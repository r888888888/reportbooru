module Reports
  class PostChanges < Base
    def version
      1
    end

    def min_changes
      400
    end

    def report_name
      "post_changes"
    end

    def sort_key
      :total
    end

    def html_template
      return <<-EOS
%html
  %head
    %title Post Change Report
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
      %caption Post changes in the past thirty days (minimum count is #{min_changes})
      %thead
        %tr
          %th User
          %th Level
          %th Total
          %th Rat
          %th Src
          %th Add
          %th Rem
          %th Art
          %th Char
          %th Copy
          %th Gen
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:level_string]
            %td= datum[:total]
            %td= datum[:rating]
            %td= datum[:source]
            %td= datum[:added]
            %td= datum[:removed]
            %td= datum[:artist]
            %td= datum[:character]
            %td= datum[:copyright]
            %td= datum[:general]
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}"
EOS
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      name = user.name
      client = BigQuery::PostVersion.new(date_window)
      total = client.count_changes(user_id)
      rating = client.count_rating_changed(user_id)
      source = client.count_source_changed(user_id)
      added = client.count_added(user_id)
      removed = client.count_removed(user_id)
      artist = client.count_artist_added(user_id)
      character = client.count_character_added(user_id)
      copyright = client.count_copyright_added(user_id)
      general = client.count_general_added(user_id)

      return {
        id: user_id,
        name: name,
        level: user.level,
        level_string: user.level_string,
        total: total,
        rating: rating,
        source: source,
        added: added,
        removed: removed,
        artist: artist,
        character: character,
        copyright: copyright,
        general: general
      }
    end

    def candidates
      DanbooruRo::PostVersion.where("updated_at > ?", date_window).group("updater_id").having("count(*) > ?", min_changes).pluck(:updater_id)
    end
  end
end
