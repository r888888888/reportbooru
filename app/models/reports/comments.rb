=begin
from brokeneagle98:

Total: total comments created/user
Updates: total of comments where 'created_at' != 'updated_at'
Bumps: total where 'do_not_bump_post' == false
Pos Count: total where 'score' > 0
Neg Count: total where 'score' < 0
Score: cumulative score for all comments
=end

module Reports
	class Comments < Base
    def version
      1
    end

    def min_changes
      10
    end

    def report_name
      "comments"
    end

    def sort_key
      :total
    end

    def html_template
      return <<-EOS
%html
  %head
    %title Comments Report
    %meta{:name => "viewport", :content => "width=device-width, initial-scale=1"}
    %script{:src => "/reports/assets/jquery-3.1.1.slim.min.js"}
    %script{:src => "/reports/assets/jquery.tablesorter.min.js"}
    %link{:rel => "stylesheet", :href => "/reports/assets/pure.css"}
    %script
      :javascript
        $(function() {
          $("#report").tablesorter();
        });
  %body
    %table{:id => "report", :class => "pure-table pure-table-bordered pure-table-striped"}
      %caption Comments (over past thirty days, minimum count is #{min_changes})
      %thead
        %tr
          %th User
          %th Total
          %th Updates
          %th Bumps
          %th Pos Score
          %th Neg Score
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:total]
            %td= datum[:updates]
            %td= datum[:bumps]
            %td= datum[:pos]
            %td= datum[:neg]
EOS
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)

      return {
        id: user.id,
        name: user.name,
        total: DanbooruRo::Comment.where("created_at > ? and creator_id = ?", date_window, user.id).count,
        updates: DanbooruRo::Comment.where("created_at > ? and creator_id = ? and updated_at <> created_at", date_window, user.id).count,
        bumps: DanbooruRo::Comment.where("created_at > ? and creator_id = ? and do_not_bump_post = false", date_window, user.id).count,
        pos: DanbooruRo::Comment.where("created_at > ? and creator_id = ? and score > 0", date_window, user.id).count,
        neg: DanbooruRo::Comment.where("created_at > ? and creator_id = ? and score < 0", date_window, user.id).count
      }
    end

		def candidates
			DanbooruRo::Comment.where("created_at > ?", date_window).group("creator_id").having("count(*) > ?", min_changes).pluck(:creator_id)
		end
	end
end

