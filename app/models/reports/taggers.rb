module Reports
	class Taggers < Base
		def version
			1
		end

    def report_name
      "taggers"
    end

    def sort_key
      :tags_per_upload
    end

		def html_template
      return <<-EOS
%html
  %head
    %title Tagger Report
    %meta{:name => "viewport", :content => "width=device-width, initial-scale=1"}
    %script{:src => "/reports/assets/jquery-3.1.1.slim.min.js"}
    %script{:src => "/reports/assets/jquery.tablesorter.min.js"}
    %link{:rel => "stylesheet", :href => "/reports/assets/pure.css"}
    :javascript
      $(function() {
        $("#report").tablesorter();
      });
  %body
    %table{:id => "report", :class => "pure-table pure-table-bordered pure-table-striped"}
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
              %a{:class => "user-#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:contrib]
            %td= datum[:tags_per_upload]
            %td= datum[:total]
EOS
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
        level: user.level,
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
