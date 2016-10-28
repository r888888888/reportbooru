=begin
from brokeneagle98:

Total: total BUR created/user
Approved: total where 'status' == 'approved'
Rejected: total where 'rejected' == 'rejected'
=end

module Reports
	class BulkUpdateRequests < Base
    def version
      1
    end

    def min_changes
      10
    end

    def report_name
      "bulk_update_requests"
    end

    def sort_key
      :count
    end

    def html_template
      return <<-EOS
%html
  %head
    %title Bulk Update Request Report
    %style
      :css
        #{pure_css_tables}
    %meta{:name => "viewport", :content => "width=device-width, initial-scale=1"}
  %body
    %table{:class => "pure-table pure-table-bordered pure-table-striped"}
      %caption Bulk Update Requests (over past thirty days, minimum count is #{min_changes})
      %thead
        %tr
          %th User
          %th Count
          %th Approved
          %th Rejected
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:count]
            %td= datum[:approved]
            %td= datum[:rejected]
EOS
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)

      return {
        id: user.id,
        name: user.name,
        count: DanbooruRo::BulkUpdateRequest.where("created_at > ? and creator_id = ?", date_window, user.id).count,
        approved: DanbooruRo::BulkUpdateRequest.where("created_at > ? and creator_id = ? and status = ?", date_window, user.id, "approved").count,
        rejected: DanbooruRo::BulkUpdateRequest.where("created_at > ? and creator_id = ? and status = ?", date_window, user.id, "rejected").count
      }
    end

		def candidates
			DanbooruRo::BulkUpdateRequest.where("updated_at > ?", date_window).group("creator_id").having("count(*) > ?", min_changes).pluck(:creator_id)
		end
	end
end

