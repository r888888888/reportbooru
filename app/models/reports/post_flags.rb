=begin
Total: total post flags created/user
Successful: total where 'is_resolved' == true
=end

module Reports
  class PostFlags < Base
    def version
      1
    end

    def min_changes
      10
    end

    def report_name
      "post_flags"
    end

    def sort_key
      :count
    end
    
    def html_template
      return <<-EOS
%html
  %head
    %title Post Flags Report
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
      %caption Post flags (over past thirty days, minimum count is #{min_changes})
      %thead
        %tr
          %th User
          %th Count
          %th Resolved
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:count]
            %td= datum[:resolved]
EOS
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)

      return {
        id: user.id,
        name: user.name,
        count: DanbooruRo::PostFlag.where("created_at > ? and creator_id = ?", date_window, user.id).count,
        resolved: DanbooruRo::PostFlag.where("created_at > ? and creator_id = ? and is_resolved = true", date_window, user.id).count
      }
    end

    def candidates
      DanbooruRo::PostFlag.where("updated_at > ?", date_window).group("creator_id").having("count(*) > ?", min_changes).pluck(:creator_id)
    end
  end
end
