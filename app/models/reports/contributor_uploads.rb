module Reports
  class ContributorUploads < Uploads
    def version
      6
    end

    def html_template
      return <<-EOS
%html
  %head
    %title Contributor Upload Report
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
      %caption Unlimited uploaders over past thirty days (minimum uploads is #{min_uploads})
      %thead
        %tr
          %th User
          %th Lvl
          %th Tot
          %th Byp
          %th Del
          %th{:title => "Lower bound of 95% confidence interval for probability that an upload gets deleted"} Del Conf
          %th Unq Flag
          %th Src
          %th S
          %th Q
          %th E
          %th Gen
          %th Char
          %th Copy
          %th Art
          %th{:title => "Percentage that are comics"} Comic
          %th{:title => "Median score"} Med Score
          %th{:title => "Lower bound of 95% confidence interval for probability that an upload gets a negative score"} Neg Conf
          %th Unq Downvote
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:level_string]
            %td= datum[:total]
            %td= datum[:queue_bypass]
            %td= datum[:deleted]
            %td= datum[:del_conf]
            %td= datum[:uniq_flaggers]
            %td= datum[:source]
            %td= datum[:safe]
            %td= datum[:questionable]
            %td= datum[:explicit]
            %td= datum[:general]
            %td= datum[:character]
            %td= datum[:copyright]
            %td= datum[:artist]
            %td= datum[:comic_ratio]
            %td= datum[:med_score]
            %td= datum[:neg_conf]
            %td= datum[:uniq_downvoters]
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}"
EOS
    end

    def candidates
      DanbooruRo::User.joins("join posts on posts.uploader_id = users.id").where("posts.created_at >= ? and users.bit_prefs & ? > 0", date_window, 1 << 14).group("users.id").having("count(*) >= ?", min_uploads).pluck("distinct(users.id)")
    end

    def report_name
      "contributor_uploads"
    end

    def min_uploads
      300
    end
  end
end
