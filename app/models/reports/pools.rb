module Reports
  class Pools < Base
    def version
      2
    end

    def min_changes
      10
    end

    def report_name
      "pools"
    end

    def sort_key
      :total
    end
    
    def html_template
      return <<-EOS
%html
  %head
    %title Pool Report
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
      %caption Pools (over past thirty days, minimum count is #{min_changes})
      %thead
        %tr
          %th User
          %th Level
          %th Total
          %th Creates
          %th Adds
          %th Removes
          %th Orders
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:level_string]
            %td= datum[:total]
            %td= datum[:create]
            %td= datum[:add]
            %td= datum[:remove]
            %td= datum[:order]
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}"
EOS
    end

    def find_previous(version)
      Archive::PoolVersion.where("pool_id = ? and updated_at < ?", version.pool_id, version.updated_at).order("updated_at desc, id desc").first
    end

    def find_versions(user_id)
      Archive::PoolVersion.where("updater_id = ? and updated_at > ?", user_id, date_window)
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      total = 0
      create = 0
      add = 0
      remove = 0
      order = 0

      find_versions(user_id).find_each do |version|
        total += 1
        version_post_ids = version.post_ids
        prev = find_previous(version)

        if prev.nil?
          create += 1
        else
          add += version.added_post_ids.size
          remove += version.removed_post_ids.size

          if version.added_post_ids.empty? && version.removed_post_ids.empty?
            order += 1
          end
        end
      end

      return {
        id: user.id,
        name: user.name,
        level: user.level,
        level_string: user.level_string,
        total: total,
        create: create,
        add: add,
        remove: remove,
        order: order
      }
    end
    
    def candidates
      Archive::PoolVersion.where("updated_at > ?", date_window).group("updater_id").having("count(*) >= ?", min_changes).pluck(:updater_id)
    end
  end
end
