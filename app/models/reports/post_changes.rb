require 'google/apis/storage_v1'

module Reports
  class PostChanges < Base
    VERSION = 1
    MINIMUM_CHANGES_IN_A_MONTH = 400
    HTML_TEMPLATE = <<EOS
%html
  %header
    %title Post Change Report
  %body
    %table
      %thead
        %tr
          %th User
          %th Total
          %th Rat
          %th Src
          %th Add
          %th Rem
          %th Art
          %th Char
          %th Copy
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:total]
            %td= datum[:rating]
            %td= datum[:source]
            %td= datum[:added]
            %td= datum[:removed]
            %td= datum[:artist]
            %td= datum[:character]
            %td= datum[:copyright]
EOS

    def date_string
      Time.now.strftime("%Y-%m-%d")
    end

    def file_name
      "post-changes_#{date_string}_v#{VERSION}"
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

    def calculate_data(user_id)
      name = DanbooruRo::User.find(user_id).name
      client = BigQuery::PostVersion.new
      total = client.count_changes(user_id)
      rating = client.count_rating_changed(user_id)
      source = client.count_source_changed(user_id)
      added = client.count_added(user_id)
      removed = client.count_removed(user_id)
      artist = client.count_artist_added(user_id)
      character = client.count_character_added(user_id)
      copyright = client.count_copyright_added(user_id)

      return {
        id: user_id,
        name: name,
        total: total,
        rating: rating,
        source: source,
        added: added,
        removed: removed,
        artist: artist,
        character: character,
        copyright: copyright
      }
    end

    def upload(file, name, content_type)
      data = {
        content_type: content_type
      }

      storage_service.insert_object("danbooru-reports", data, name: "post-changes/#{name}", content_type: content_type, upload_source: file.path)
    end

    def candidates
      DanbooruRo::PostVersion.where("updated_at > ?", 30.days.ago).group("updater_id").having("count(*) > ?", MINIMUM_CHANGES_IN_A_MONTH).pluck(:updater_id)
    end
  end
end
