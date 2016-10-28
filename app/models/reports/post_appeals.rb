=begin
from brokeneagle98:

Total: total post appeals created/user
Successful: total where 'is_resolved' == true
=end

module Reports
	class PostAppeals < Base
    def version
      1
    end

    def min_changes
      10
    end

    def report_name
      "post_appeals"
    end

    def sort_key
      :count
    end
    
    def html_template
      return <<-EOS
%html
  %head
    %title Post Appeals Report
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
      %caption Post appeals (over past thirty days, minimum count is #{min_changes})
      %thead
        %tr
          %th User
          %th Count
          %th Resolved
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:count]
            %td= datum[:resolved]
EOS
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)

      return {
        id: user.id,
        name: user.name,
        level: user.level,
        count: DanbooruRo::PostAppeal.where("created_at > ? and creator_id = ?", date_window, user.id).count,
        resolved: DanbooruRo::PostAppeal.joins("join posts on posts.id = post_appeals.id").where("post_appeals.created_at > ? and post_appeals.creator_id = ? and posts.is_deleted = false and posts.is_flagged = false", date_window, user.id).count
      }
    end
		
		def candidates
			DanbooruRo::PostAppeal.where("updated_at > ?", date_window).group("creator_id").having("count(*) > ?", min_changes).pluck(:creator_id)
		end
	end
end
