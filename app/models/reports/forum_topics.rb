=begin
from brokeneagle98:

Total: total forum topics created/user
Replies: cumulative total of 'response_count'
=end

module Reports
	class ForumTopics < Base
    def version
      1
    end

    def min_changes
      10
    end

    def report_name
      "forum_topics"
    end

    def sort_key
      :total
    end
    
    def html_template
      return <<-EOS
%html
  %head
    %title Forum Topics Report
    %style
      :css
        #{pure_css_tables}
    %meta{:name => "viewport", :content => "width=device-width, initial-scale=1"}
  %body
    %table{:class => "pure-table pure-table-bordered pure-table-striped"}
      %caption Forum Topics (over past thirty days, minimum count is #{min_changes})
      %thead
        %tr
          %th User
          %th Total
          %th Tag Cat
          %th Bug Cat
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:total]
            %td= datum[:tag_cat]
            %td= datum[:bug_cat]
EOS
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)

      return {
        id: user.id,
        name: user.name,
        total: DanbooruRo::ForumTopic.where("created_at > ? and creator_id = ?", date_window, user.id).count,
        tag_cat: DanbooruRo::ForumTopic.where("created_at > ? and creator_id = ? and category_id = 1", date_window, user.id).count,
        bug_cat: DanbooruRo::ForumTopic.where("created_at > ? and creator_id = ? and category_id = 2", date_window, user.id).count
      }
    end
		
		def candidates
			DanbooruRo::ForumTopic.where("created_at > ?", date_window).group("creator_id").having("count(*) > ?", min_changes).pluck(:creator_id)
		end
	end
end
