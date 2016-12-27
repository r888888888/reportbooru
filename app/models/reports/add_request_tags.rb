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
    %script{:src => "/user-reports/assets/jquery-3.1.1.slim.min.js"}
    %script{:src => "/user-reports/assets/jquery.tablesorter.min.js"}
    %link{:rel => "stylesheet", :href => "/user-reports/assets/pure.css"}
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
          %th +Total
          %th -Total
          %th +tagme
          %th -tagme
          %th +art
          %th -art
          %th +copy
          %th -copy
          %th +char
          %th -char
          %th +source
          %th -source
          %th +note
          %th -note
          %th +annot
          %th -annot
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:total]
            %td= datum[:total_add]
            %td= datum[:total_rem]
            %td= datum[:tagme_add]
            %td= datum[:tagme_rem]
            %td= datum[:artist_add]
            %td= datum[:artist_rem]
            %td= datum[:copy_add]
            %td= datum[:copy_rem]
            %td= datum[:char_add]
            %td= datum[:char_rem]
            %td= datum[:source_add]
            %td= datum[:source_rem]
            %td= datum[:note_add]
            %td= datum[:note_rem]
            %td= datum[:annot_add]
            %td= datum[:annot_rem]
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
      h[:total_add] = h[:tagme_add].to_i + h[:artist_add].to_i + h[:copy_add].to_i + h[:char_add].to_i + h[:source_add].to_i + h[:note_add].to_i + h[:annot_add].to_i
      h[:total_rem] = h[:tagme_rem].to_i + h[:artist_rem].to_i + h[:copy_rem].to_i + h[:char_rem].to_i + h[:source_rem].to_i + h[:note_rem].to_i + h[:annot_rem].to_i
      h[:total] = h[:total_add] + h[:total_rem]
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
