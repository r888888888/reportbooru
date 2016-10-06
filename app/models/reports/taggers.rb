module Reports
	class Taggers < Base
		def version
			1
		end

    def report_name
      "taggers"
    end

		def html_template
      return <<-EOS
%html
  %header
    %title Tagger Report
    %link{:rel => "stylesheet", :href => "http://yui.yahooapis.com/pure/0.6.0/pure-min.css"}
  %body
    %table{:class => "pure-table-striped"}
      %caption Uploaders and average number of initial tags used (over past thirty days, minimum uploads is #{min_uploads})
      %thead
        %tr
          %th User
          %th Contrib
          %th Tags/Upload
          %th Uploads
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:contrib]
            %td= datum[:tags_per_upload]
            %td= datum[:total]
EOS
		end

    def generate
      htmlf = Tempfile.new("#{file_name}_html")
      jsonf = Tempfile.new("#{file_name}_json")

      begin
        data = []

        candidates.each do |user_id|
          data << calculate_data(user_id)
        end

        data = data.sort_by {|x| -x[:tags_per_upload].to_i}

        engine = Haml::Engine.new(html_template)
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
      user = DanbooruRo::User.find(user_id)
      tda = date_window.strftime("%F %H:%M")
      client = BigQuery::PostVersion.new
      total = DanbooruRo::Post.where("created_at > ? and uploader_id = ?", date_window, user_id).count
      tags = client.count_any_added_v1(user_id, tda)
      contrib = user.can_upload_free? ? "Y" : nil

      return {
        id: user.id,
        name: user.name,
        total: total,
        contrib: contrib,
        tags_per_upload: tags.to_i / total.to_i
      }
    end

		def min_uploads
			100
		end

		def candidates
			DanbooruRo::Post.where("posts.created_at > ?", date_window).group("posts.uploader_id").having("count(*) > ?", min_uploads).pluck("posts.uploader_id")
 		end
	end
end
