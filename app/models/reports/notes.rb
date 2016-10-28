=begin
from brokeneagle98:

Total: total versions/user
Creates: no prior version
Edits: body changed
Moves: x,y changes
Resizes: width,height changes
Deletes: isactive "True" -> "False"
Undeletes: isactive "True" -> "False"
=end

module Reports
	class Notes < Base
		def version
			1
		end

		def min_changes
			100
		end

		def report_name
			"notes"
		end

    def sort_key
      :creates
    end
		
		def html_template
      return <<-EOS
%html
  %head
    %title Note Report
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
      %caption Note changes (over past thirty days, minimum changes is #{min_changes})
      %thead
        %tr
          %th User
          %th Contrib
          %th Creates
          %th Edits
          %th Moves
          %th Resizes
          %th Deletes
          %th Undeletes
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:contrib]
            %td= datum[:creates]
            %td= datum[:edits]
            %td= datum[:moves]
            %td= datum[:resizes]
            %td= datum[:deletes]
            %td= datum[:undeletes]
EOS
		end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      tda = date_window.strftime("%F %H:%M")
      client = BigQuery::NoteVersion.new
      contrib = user.can_upload_free? ? "Y" : nil

      return {
        id: user.id,
        name: user.name,
        creates: client.count_creates(user_id, tda),
        contrib: contrib,
        edits: client.count_edits(user_id, tda),
        moves: client.count_moves(user_id, tda),
        resizes: client.count_resizes(user_id, tda),
        deletes: client.count_deletes(user_id, tda),
        undeletes: client.count_undeletes(user_id, tda)
      }
    end

		def candidates
			DanbooruRo::NoteVersion.where("updated_at > ?", date_window).group("updater_id").having("count(*) > ?", min_changes).pluck(:updater_id)
		end
	end
end
