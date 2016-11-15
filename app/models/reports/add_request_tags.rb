module Reports
  class AddRequestTags < Base
    def version
      1
    end

    def html_template
      return <<-EOS
%html
  %head
    %title Add Request Tags Report
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
      %caption Add request tags over the past thirty days (minimum changes is #{min_changes})
      %thead
        %tr
          %th User
          %th Total
          %th tagme
          %th artist
          %th copy
          %th char
          %th source
          %th note
          %th annot
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= "#{datum[:total_add]}/#{datum[:total_rem]}"
            %td= "#{datum[:tagme_add]}/#{datum[:tagme_rem]}"
            %td= "#{datum[:artist_add]}/#{datum[:artist_rem]}"
            %td= "#{datum[:copy_add]}/#{datum[:copy_rem]}"
            %td= "#{datum[:char_add]}/#{datum[:char_rem]}"
            %td= "#{datum[:source_add]}/#{datum[:source_rem]}"
            %td= "#{datum[:note_add]}/#{datum[:note_rem]}"
            %td= "#{datum[:annot_add]}/#{datum[:annot_rem]}"
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}"
EOS
    end

    def candidates
      client = BigQuery::PostVersion.new(date_window)
      client.add_request_tag_candidates(min_changes)
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      client = BigQuery::PostVersion.new(date_window)

      h = {
        id: user.id,
        name: user.name,
        level: user.level,
        level_string: user.level_string,
        tagme_add: client.count_tag_added(user_id, "tagme"),
        tagme_rem: client.count_tag_removed(user_id, "tagme"),
        artist_add: client.count_tag_added(user_id, "artist_request"),
        artist_rem: client.count_tag_removed(user_id, "artist_request"),
        copy_add: client.count_tag_added(user_id, "copyright_request"),
        copy_rem: client.count_tag_removed(user_id, "copyright_request"),
        char_add: client.count_tag_added(user_id, "character_request"),
        char_rem: client.count_tag_removed(user_id, "character_request"),
        source_add: client.count_tag_added(user_id, "check_pixiv_source"),
        source_rem: client.count_tag_removed(user_id, "check_pixiv_source"),
        note_add: client.count_tag_added(user_id, "check_my_note"),
        note_rem: client.count_tag_removed(user_id, "check_my_note"),
        annot_add: client.count_tag_added(user_id, "annotated"),
        annot_rem: client.count_tag_removed(user_id, "annotated")
      }
      h[:total_add] = h[:tagme_add] + h[:artist_add] + h[:copy_add] + h[:char_add] + h[:source_add] + h[:note_add] + h[:annot_add]
      h[:total_rem] = h[:tagme_rem] + h[:artist_rem] + h[:copy_rem] + h[:char_rem] + h[:source_rem] + h[:note_rem] + h[:annot_rem]
      h
    end

    def report_name
      "add_request_tags"
    end
    
    def sort_key
      :total
    end

    def min_changes
      25
    end
  end
end
