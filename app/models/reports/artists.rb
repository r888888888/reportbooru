=begin
from brokeneagle98:

Total: total versions/user
Creates: no prior version
Name: name changed
Other Name: other names changed
Url: url string changed
Group: group name changed
Deletes: isactive "True" -> "False"
Undeletes: isactive "True" -> "False"
Other: no changes, i.e. none of the conditions above are true
The following is determined by searching for a corresponding wiki page version
Wiki:
  Search for wiki page with same 'title' as artist 'name'; if none exists then break
  Search through wiki page versions for
    wiki page version 'updated_at' timestamp within 1 second of artist version 'updated_at' timestamp
      and
    wiki page version 'updater_id' equal to artist version 'updater_id'
=end

module Reports
  class Artists < Base
    def version
      1
    end

    def min_changes
      20
    end

    def report_name
      "artists"
    end

    def sort_key
      :total
    end
    
    def html_template
      return <<-EOS
%html
  %head
    %title Artist Report
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
      %caption Artist changes (over past thirty days, minimum changes is #{min_changes})
      %thead
        %tr
          %th User
          %th Level
          %th Total
          %th Creates
          %th Name
          %th Oth Name
          %th Url
          %th Group
          %th Del
          %th Undel
          %th Wiki
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:level_string]
            %td= datum[:total]
            %td= datum[:creates]
            %td= datum[:name_changes]
            %td= datum[:other]
            %td= datum[:url]
            %td= datum[:group]
            %td= datum[:delete]
            %td= datum[:undelete]
            %td= datum[:wiki]
    %p= "Since #{date_window.utc} to #{Time.now.utc}"
EOS
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      tda = date_window.strftime("%F %H:%M")
      client = BigQuery::ArtistVersion.new
      total = client.count_total(user_id, tda)
      creates = client.count_creates(user_id, tda)
      name_changes = client.count_name(user_id, tda)
      other = client.count_other(user_id, tda)
      url = client.count_url(user_id, tda)
      group = client.count_group(user_id, tda)
      delete = client.count_delete(user_id, tda)
      undelete = client.count_undelete(user_id, tda)
      wiki = client.count_wiki(user_id, tda)

      return {
        id: user.id,
        name: user.name,
        level: user.level,
        level_string: user.level_string,
        total: total,
        creates: creates,
        name_changes: name_changes,
        other: other,
        url: url,
        group: group,
        delete: delete,
        undelete: undelete,
        wiki: wiki
      }
    end

    def candidates
      DanbooruRo::ArtistVersion.where("updated_at > ?", date_window).group("updater_id").having("count(*) > ?", min_changes).pluck(:updater_id)
    end
  end
end
