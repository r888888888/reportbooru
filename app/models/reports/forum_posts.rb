=begin
from brokeneagle98:

Total: total forum posts created/user
Updates: total of forum posts where 'created_at' != 'updated_at'
=end

module Reports
	class ForumPosts < Base
    def version
      1
    end

    def min_changes
      10
    end

    def report_name
      "forum_posts"
    end

    def sort_key
      :total
    end
    
    def html_template
      return <<-EOS
%html
  %head
    %title Forum Posts Report
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
      %caption Forum Posts (over past thirty days, minimum count is #{min_changes})
      %thead
        %tr
          %th User
          %th Level
          %th Total
          %th Updates
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:level_string]
            %td= datum[:total]
            %td= datum[:updates]
EOS
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)

      return {
        id: user.id,
        name: user.name,
        level: user.level,
        level_string: user.level_string,
        total: DanbooruRo::ForumPost.where("created_at > ? and creator_id = ?", date_window, user.id).count,
        updates: DanbooruRo::ForumPost.where("created_at > ? and creator_id = ? and created_at <> updated_at", date_window, user.id).count
      }
    end
		
		def candidates
			DanbooruRo::ForumPost.where("created_at > ?", date_window).group("creator_id").having("count(*) > ?", min_changes).pluck(:creator_id)
		end
	end
end
