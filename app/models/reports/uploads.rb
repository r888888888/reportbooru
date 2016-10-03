module Reports
  class Uploads < Base
    VERSION = 1
    HTML_TEMPLATE = <<EOS
%html
  %header
    %title Upload Report
  %body
    %table
      %thead
        %tr
          %th User
          %th Total
          %th Del
          %th Par
          %th Src
          %th S
          %th Q
          %th E
          %th Gen
          %th Char
          %th Copy
          %th Art
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:total]
            %td= datum[:queue_bypass]
            %td= datum[:deleted]
            %td= datum[:source]
            %td= datum[:safe]
            %td= datum[:questionable]
            %td= datum[:explicit]
            %td= datum[:general]
            %td= datum[:character]
            %td= datum[:copyright]
            %td= datum[:artist]
EOS

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      name = user.name
      client = BigQuery::PostVersion.new
      tda = 30.days.ago.strftime("%F")
      total = DanbooruRo::Post.where("created_at > ?", tda).where(uploader_id: user.id).count
      queue_bypass = DanbooruRo::Post.where("created_at > ?", tda).where(uploader_id: user.id, approver_id: nil, is_deleted: false, is_pending: false).count
      deleted = DanbooruRo::Post.where("created_at > ?", tda).where(uploader_id: user.id, is_deleted: false).count
      parent = DanbooruRo::Post.where("parent_id is not null and created_at > ?", tda).where(uploader_id: user.id).count
      source = DanbooruRo::Post.where("source <> '' and source is not null and created_at > ?", tda).where(uploader_id: user.id).count
      safe = DanbooruRo::Post.where("created_at > ?", tda).where(uploader_id: user.id, rating: "s").count
      questionable = DanbooruRo::Post.where("created_at > ?", tda).where(uploader_id: user.id, rating: "q").count
      explicit = DanbooruRo::Post.where("created_at > ?", tda).where(uploader_id: user.id, rating: "e").count
      general = client.count_general_added_v1(user_id, tda)
      character = client.count_character_added_v1(user_id, tda)
      copyright = client.count_copyright_added_v1(user_id, tda)
      artist = client.count_artist_added_v1(user_id, tda)

      return {
        id: user_id,
        name: name,
        total: total,
        queue_bypass: queue_bypass,
        deleted: deleted,
        parent: parent,
        source: source,
        safe: safe,
        questionable: questionable,
        explicit: explicit,
        general: general,
        character: character,
        copyright: copyright,
        artist: artist
      }
    end

    def date_string
      Time.now.strftime("%F %H:%M")
    end

    def file_name
      "uploads_#{date_string}_v#{VERSION}"
    end

    def generate
      htmlf = Tempfile.new("#{file_name}_html")
      jsonf = Tempfile.new("#{file_name}_json")

      begin
        data = []

        candidates.each do |user_id|
          data << calculate_data(user_id)
        end

        data = data.sort_by {|x| -x[:total]}

        engine = Haml::Engine.new(HTML_TEMPLATE)
        htmlf.write(engine.render(Object.new, data: data))

        jsonf.write("[")
        jsonf.write(data.map {|x| x.to_json}.join(","))
        jsonf.write("]")

        htmlf.rewind
        jsonf.rewind

        upload(htmlf, "#{file_name}.html", "text/html")
        upload(jsonf, "#{file_name}.json", "application/json")
      ensure
        jsonf.close
        htmlf.close
      end
    end

    def upload(file, name, content_type)
      data = {
        content_type: content_type
      }

      storage_service.insert_object("danbooru-reports", data, name: "uploads/#{name}", content_type: content_type, upload_source: file.path)
    end

    def candidates
      DanbooruRo::User.joins("join posts on posts.uploader_id = users.id").where("posts.created_at >= ? and users.bit_prefs & ? = 0", 30.days.ago, 1 << 14).group("users.id").having("count(*) > ?", 100).pluck("distinct(users.id)")
    end
  end
end
