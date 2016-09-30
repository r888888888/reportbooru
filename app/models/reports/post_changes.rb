require 'google/apis/storage_v1'

module Reports
  class PostChanges
    VERSION = 1
    MINIMUM_CHANGES_IN_A_MONTH = 400
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
<th>Rating Changes</th>
<th>Source Changes</th>
<th>Tags Added</th>
<th>Tags Removed</th>
<th>Artists Added</th>
<th>Characters Added</th>
<th>Copyrights Added</th>
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

    def date_string
      Time.now.strftime("%Y-%m-%d")
    end

    def file_name
      "post-changes_#{date_string}_v#{VERSION}"
    end

    def generate
      jsonf = Tempfile.new("#{file_name}_json")
      htmlf = Tempfile.new("#{file_name}_html")

      jsonf.write("[")
      htmlf.write(HTML_HEADER)

      candidates.each do |user_id|
        data = calculate_data(user_id)
        write_table(htmlf, data)
        write_json(jsonf, data)
      end

      htmlf.write(HTML_FOOTER)
      jsonf.seek(-1, IO::SEEK_CUR)
      jsonf.write("]")
      htmlf.rewind
      jsonf.rewind

      upload(jsonf, "#{file_name}.json", "application/json")
      upload(htmlf, "#{file_name}.html", "text/html")
    ensure
      jsonf.close
      jsonf.unlink
      htmlf.close
      htmlf.unlink
    end

    def calculate_data(user_id)
      name = User.find(user_id).name
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
        client: client,
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

    def write_table(file, data)
      file.write("<tr>")
      file.write("<td><a href='https://danbooru.donmai.us/users/#{data[:id]}'>#{data[:name]}</a></td>")
      file.write("<td>#{data[:total]}</td>")
      file.write("<td>#{data[:rating]}</td>")
      file.write("<td>#{data[:source]}</td>")
      file.write("<td>#{data[:added]}</td>")
      file.write("<td>#{data[:removed]}</td>")
      file.write("<td>#{data[:artist]}</td>")
      file.write("<td>#{data[:character]}</td>")
      file.write("<td>#{data[:copyright]}</td>")
      file.write("</tr>")
    end

    def write_json(file, data)
      file.write(data.to_json)
      file.write(",")
    end

    def upload(file, name, content_type)
      data = {
        content_type: content_type
      }
      storage = Google::Apis::StorageV1::StorageService.new
      storage.authorization = Google::Auth.get_application_default([Google::Apis::StorageV1::AUTH_DEVSTORAGE_READ_WRITE])
      storage.insert_object("danbooru-reports", data, name: "post-changes/#{name}", content_type: content_type, upload_source: file.path)
    end

    def candidates
      PostVersion.where("updated_at > ?", 30.days.ago).group("updater_id").having("count(*) > ?", MINIMUM_CHANGES_IN_A_MONTH).pluck(:updater_id)
    end
  end
end
