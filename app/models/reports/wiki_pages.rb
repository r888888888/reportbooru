=begin
from brokeneagle98:

The following is disregarded if there is a corresponding artist version (See Artist above for implementation details)
Total: total versions/user
Creates: no prior version
Title: title changed
Other Name: other names changed
Body Edits: body changed
Other: no changes, i.e. none of the conditions above are true
=end

module Reports
	class WikiPages < Base
		def version
			2
		end

    def report_name
      "wiki_pages"
    end

    def sort_key
      :total
    end

    def min_changes
			20
		end
		
    def html_template
      return <<-EOS
%html
  %head
    %title Wiki Report
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
      %caption Wiki updaters (over past thirty days, minimum changes is #{min_changes})
      %thead
        %tr
          %th User
          %th Level
          %th Total
          %th Create
          %th Title
          %th Oth Name
          %th Body
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:level_string]
            %td= datum[:total]
            %td= datum[:creates]
            %td= datum[:titles]
            %td= datum[:others]
            %td= datum[:bodies]
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}"
EOS
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      client = BigQuery::WikiPageVersion.new(date_window)
      total = client.count_total(user_id)
      creates = client.count_creates(user_id)
      titles = client.count_title_changes(user_id)
      others = client.count_other_name_changes(user_id)
      bodies = client.count_body_changes(user_id)

      return {
        id: user.id,
        name: user.name,
        level: user.level,
        level_string: user.level_string,
        total: total,
        creates: creates,
        titles: titles,
        others: others,
        bodies: bodies
      }
    end

		def candidates
			DanbooruRo::WikiPageVersion.where("updated_at > ?", date_window).group("updater_id").having("count(*) >= ?", min_changes).pluck("updater_id")
		end
	end
end
