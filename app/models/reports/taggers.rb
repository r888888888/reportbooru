module Reports
	class Taggers < Base
		def version
			1
		end

    def report_name
      "taggers"
    end

    def sort_key
      :q2
    end

		def html_template
      return <<-EOS
%html
  %head
    %title Top Tagger Report
    %meta{:name => "viewport", :content => "width=device-width, initial-scale=1"}
    %script{:src => "/user-reports/assets/jquery-3.1.1.slim.min.js"}
    %script{:src => "/user-reports/assets/jquery.tablesorter.min.js"}
    %link{:rel => "stylesheet", :href => "/user-reports/assets/pure.css"}
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
          %th Level
          %th Med Tags/Upload
          %th{:title => "25th percentile tags/upload"} Low Quart
          %th{:title => "75th percentile tags/upload"} Up Quart
          %th Uploads
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:level_string]
            %td= datum[:q2]
            %td= datum[:q1]
            %td= datum[:q3]
            %td= datum[:total]
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}"
EOS
		end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      client = BigQuery::PostVersion.new(date_window)
      total = DanbooruRo::Post.where("created_at > ? and uploader_id = ?", date_window, user_id).count
      tags = client.count_any_added_v1(user_id)
      q1, q2, q3 = client.quantiles_v1(user_id)

      return {
        id: user.id,
        name: user.name,
        level: user.level,
        level_string: user.level_string,
        total: total,
        q1: q1,
        q2: q2,
        q3: q3
      }
    end

		def min_uploads
			50
		end

		def candidates
			DanbooruRo::Post.where("posts.created_at > ?", date_window).group("posts.uploader_id").having("count(*) > ?", min_uploads).pluck("posts.uploader_id")
 		end
	end
end
