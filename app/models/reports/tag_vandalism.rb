module Reports
  class TagVandalism < Base
    def version
      1
    end

    def min_changes
      10
    end

    def report_name
      "tag_vandalism"
    end
    
    def html_template
      return <<-EOS
%html
  %head
    %title Tag Vandalism Report
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
      %caption Tag vandalism (over past thirty days, minimum changes is #{min_changes})
      %thead
        %tr
          %th User
          %th Level
          %th Account Age
          %th Change
          %th Count
      %tbody
        - data.compact.flatten.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:level_string]
            %td= datum[:age]
            %td= datum[:change]
            %td= datum[:count]
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}"
EOS
    end

    def sort(data)
      data
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      counts = Hash.new {|h, k| h[k] = 0}

      DanbooruRo::PostVersion.where(updater_id: user_id).where("updated_at > ?", date_window).find_each do |version|
        if version.previous
          diff = version.diff(version.previous)
          key = []
          key += diff[:removed_tags].map {|x| "-#{x}"}
          key += diff[:added_tags].map {|x| "+#{x}"}
          counts[key.join(" ")] += 1
        end
      end

      counts.reject! {|k, v| v < min_changes / 2}
      results = []

      counts.each do |change, count|
        results << {
          id: user.id,
          name: user.name,
          level: user.level,
          age: user.created_at.strftime("%F"),
          level_string: user.level_string,
          change: change,
          count: count
        }
      end

      results
    end

    def candidates
      DanbooruRo::PostVersion.joins("join users on users.id = post_versions.updater_id").where("post_versions.updated_at > ? and users.level = ?", date_window, 20).group("post_versions.updater_id").having("count(*) > ?", min_changes).pluck(:updater_id)
    end
  end
end
