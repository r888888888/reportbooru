module Reports
  class InactiveApprovers < Uploads
    def sort_key
      :total
    end

    def version
      1
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
      %caption Inactive Approvers over past thirty days (maximum approvals is #{max_approvals}, does not count disapprovals)
      %thead
        %tr
          %th User
          %th Total
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:total]
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}"
EOS
    end

    def candidates
      DanbooruRo::Post.where("created_at > ? and approver_id is not null", date_window).group("approver_id").having("count(*) < ?", max_approvals).pluck(:approver_id)
    end

    def report_name
      "inactive_approvers"
    end

    def max_approvals
      30
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      name = user.name
      total = DanbooruRo::Post.where("created_at > ?", date_window).where(approver_id: user.id).count

      return {
        id: user_id,
        name: name,
        level: user.level,
        total: total
      }
    end
  end
end
