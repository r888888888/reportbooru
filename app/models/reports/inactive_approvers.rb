module Reports
  class InactiveApprovers < Uploads
    def sort_key
      :total
    end

    def version
      2
    end

    def html_template
      return <<-EOS
%html
  %head
    %title Inactive Approver Report
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
      %caption Inactive Approvers over past thirty days (maximum changes is #{max_approvals})
      %thead
        %tr
          %th User
          %th Total
          %th Approval
          %th Disapproval
          %th{:title => "in months"} Age
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:total]
            %td= datum[:approval]
            %td= datum[:disapproval]
            %td= datum[:age]
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}"
EOS
    end

    def candidates
      (DanbooruRo::PostApproval.where("created_at > ?", date_window).group("user_id").having("count(*) < ?", max_approvals).pluck("user_id") + DanbooruRo::PostDisapproval.where("created_at > ?", date_window).group("user_id").having("count(*) < ?", max_approvals).pluck("user_id")).uniq
    end

    def report_name
      "inactive_approvers"
    end

    def max_approvals
      30
    end

    def sort(data)
      data.compact.sort_by {|x| -x[:total].to_i}
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      name = user.name
      approval = DanbooruRo::PostApproval.where("created_at > ? and user_id = ?", date_window, user.id).count
      disapproval = DanbooruRo::PostDisapproval.where("created_at > ? and user_id = ?", date_window, user.id).count
      total = approval + disapproval
      if total > max_approvals
        return nil
      end
      age = ((Date.today - user.created_at.to_date) / 30).to_i

      return {
        id: user_id,
        name: name,
        level: user.level,
        total: total,
        approval: approval,
        disapproval: disapproval,
        age: age
      }
    end
  end
end
