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
    %script{:src => "/user-reports/assets/jquery-3.1.1.slim.min.js"}
    %script{:src => "/user-reports/assets/jquery.tablesorter.min.js"}
    %link{:rel => "stylesheet", :href => "/user-reports/assets/pure.css"}
    :javascript
      $(function() {
        $("#report").tablesorter();
      });
  %body
    %table{:id => "report", :class => "pure-table pure-table-bordered pure-table-striped"}
      %caption Common tag changes (over past thirty days, minimum changes is #{min_changes}, not all users are suspected vandals)
      %thead
        %tr
          %th User
          %th Level
          %th Account Age
          %th Change
          %th Count
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:level_string]
            %td= datum[:age]
            %td= datum[:change]
            %td= datum[:count]
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}. Users are basic members who have fewer than 100 changes before the period. Only changes that removed a tag are counted."
EOS
    end

    def sort(data)
      data.compact.flatten.sort_by {|x| -x[:count].to_i}
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      return nil unless user.level == 20
      counts = Hash.new {|h, k| h[k] = 0}

      Archive::PostVersion.where(updater_id: user_id).where("updated_at > ?", date_window).find_each do |version|
        if version.previous
          diff = version.diff(version.previous)
          if diff[:removed_tags].any?
            key = []
            key += diff[:removed_tags].map {|x| "-#{x}"}
            key += diff[:added_tags].map {|x| "+#{x}"}
            counts[key.join(" ")] += 1
          end
        end
      end

      counts.reject! {|k, v| v < min_changes}
      counts.reject! {|k, v| k == "-translation_request +translated"}
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
      ids = Archive::PostVersion.where("post_versions.updated_at > ?", date_window).group("post_versions.updater_id").having("count(*) > ?", min_changes).pluck(:updater_id)
      ids.select do |user_id|
        Archive::PostVersion.where("updated_at < ? and updated_at > ? and updater_id = ?", date_window, 1.year.ago, user_id).count < 100
      end
    end
  end
end
