module Reports
  class Uploads
    VERSION = 1
    HTML_HEADER = <<-EOS
<html>
<header>
<title>Post Change Report</title>
</header>
<body>
<table>
<thead>
<tr>
<th>User</th>
<th>Total</th>
<th>Deleted</th>
<th>Parent</th>
<th>Source</th>
<th>S</th>
<th>Q</th>
<th>E</th>
<th>Gen</th>
<th>Char</th>
<th>Copy</th>
<th>Art</th>
</tr>
</thead>
<tbody>
EOS
    HTML_FOOTER = <<-EOS
</tbody>
</table>
</body>
</html>
EOS

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      name = user.name
      client = BigQuery::PostVersion.new
      total = DanbooruRo::Post.where("created_at > ?", 30.days.ago).where(uploader_id: user.id).count
      queue_bypass = DanbooruRo::Post.where("created_at > ?", 30.days.ago).where(uploader_id: user.id, approver_id: nil, is_deleted: false, is_pending: false).count
      deleted = DanbooruRo::Post.where("created_at > ?", 30.days.ago).where(uploader_id: user.id, is_deleted: false).count
      parent = DanbooruRo::Post.where("parent_id is not null and created_at > ?", 30.days.ago).where(uploader_id: user.id).count
      source = DanbooruRo::Post.where("source <> '' and source is not null and created_at > ?", 30.days.ago).where(uploader_id: user.id).count
      safe = DanbooruRo::Post.where("created_at > ?", 30.days.ago).where(uploader_id: user.id, rating: "s").count
      questionable = DanbooruRo::Post.where("created_at > ?", 30.days.ago).where(uploader_id: user.id, rating: "q").count
      explicit = DanbooruRo::Post.where("created_at > ?", 30.days.ago).where(uploader_id: user.id, rating: "e").count
      general = client.count_general_added_v1(user_id, date_string)
      character = client.count_character_added_v1(user_id, date_string)
      copyright = client.count_copyright_added_v1(user_id, date_string)
      artist = client.count_artist_added_v1(user_id, date_string)

      return {
        id: user_id,
        name: name,
        client: client,
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
      30.days.ago.strftime("%Y-%m-%d")
    end

    def file_name
      s = Time.now.strftime("%Y-%m-%d")
      "uploads_#{s}_v#{VERSION}"
    end

    def generate
      data = []

      candidates.each do |user_id|
        data << calculate_data(user_id)
      end

      data = data.sort_by {|x| -x[:total]}

      htmlf = Tempfile.new("#{file_name}_html")
      htmlf.write(HTML_HEADER)
      htmlf.write(data.map {|x| to_html(x)}.join("\n"))
      htmlf.write(HTML_FOOTER)

      jsonf = Tempfile.new("#{file_name}_json")
      jsonf.write("[")
      jsonf.write(data.map {|x| to_json(x)}.join(","))
      jsonf.write("]")

      htmlf.rewind
      jsonf.rewind

      upload(htmlf, "#{file_name}.html", "text/html")
      upload(jsonf, "#{file_name}.json", "application/json")
    ensure
      jsonf.close
      htmlf.close
    end

    def to_html(data)
      s = ""
      s << ("<tr>")
      s << ("<td><a href='https://danbooru.donmai.us/users/#{data[:id]}'>#{data[:name]}</a></td>")
      s << ("<td>#{data[:total]}</td>")
      s << ("<td>#{data[:queue_bypass]}</td>")
      s << ("<td>#{data[:deleted]}</td>")
      s << ("<td>#{data[:source]}</td>")
      s << ("<td>#{data[:safe]}</td>")
      s << ("<td>#{data[:questionable]}</td>")
      s << ("<td>#{data[:explicit]}</td>")
      s << ("<td>#{data[:general]}</td>")
      s << ("<td>#{data[:character]}</td>")
      s << ("<td>#{data[:copyright]}</td>")
      s << ("<td>#{data[:artist]}</td>")
      s << ("</tr>")
    end

    def to_json(data)
      data.to_json
    end

    def upload(file, name, content_type)
      data = {
        content_type: content_type
      }

      storage_service.insert_object("danbooru-reports", data, name: "uploads/#{name}", content_type: content_type, upload_source: file.path)
    end

    def storage_service
      @_storage_service ||= begin
        s = Google::Apis::StorageV1::StorageService.new
        s.authorization = Google::Auth.get_application_default([Google::Apis::StorageV1::AUTH_DEVSTORAGE_READ_WRITE])
        s
      end
    end

    def candidates
      DanbooruRo::User.joins("join posts on posts.uploader_id = users.id").where("posts.created_at >= ? and users.bit_prefs & ? = 0", 30.days.ago, 1 << 14).group("users.id").having("count(*) > ?", 100).pluck("distinct(users.id)")
    end
  end
end
