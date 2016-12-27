=begin
from brokeneagle98:

Total: total versions/user
Creates: no prior version
Orig Title: Original Title changed
Orig Descr: Original Body changed
Trans Title: Translated Title changed
Trans Descr: Translated Body changed
Other: no changes, i.e. none of the conditions above are true
=end

module Reports
	class ArtistCommentaries < Base
    def version
      1
    end

    def min_changes
      10
    end

    def report_name
      "artist_commentaries"
    end

    def sort_key
      :total
    end

    def html_template
      return <<-EOS
%html
  %head
    %title Artist Commentary Report
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
      %caption Artist Commentaries (over past thirty days, minimum count is #{min_changes})
      %thead
        %tr
          %th User
          %th Level
          %th Total
          %th Creates
          %th Orig Title
          %th Orig Desc
          %th Trans Title
          %th Trans Desc
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:level_string]
            %td= datum[:total]
            %td= datum[:creates]
            %td= datum[:orig_title]
            %td= datum[:orig_desc]
            %td= datum[:trans_title]
            %td= datum[:trans_desc]
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}"
EOS
    end

    def find_previous(version)
      DanbooruRo::ArtistCommentaryVersion.where("post_id = ? and updated_at < ?", version.post_id, version.updated_at).order("updated_at desc, id desc").first
    end

    def find_versions(user_id)
    	DanbooruRo::ArtistCommentaryVersion.where("updater_id = ? and updated_at > ?", user_id, date_window)
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      total = 0
      creates = 0
      orig_title = 0
      orig_desc = 0
      trans_title = 0
      trans_desc = 0

      find_versions(user_id).each do |version|
      	total += 1
      	prev = find_previous(version)

      	if prev.nil?
      		creates += 1
      	else
	      	if version.original_title != prev.original_title
   	  	 		orig_title += 1
    	  	end

    	  	if version.original_description != prev.original_description
    	  		orig_desc += 1
    	  	end

    	  	if version.translated_title != prev.translated_title
    	  		trans_title += 1
    	  	end

    	  	if version.translated_description != prev.translated_description
    	  		trans_desc += 1
    	  	end
    	  end
      end

      return {
        id: user.id,
        level: user.level,
        level_string: user.level_string,
        name: user.name,
        total: total,
        creates: creates,
        orig_title: orig_title,
        orig_desc: orig_desc,
        trans_title: trans_title,
        trans_desc: trans_desc
      }
    end

		def candidates
			DanbooruRo::ArtistCommentaryVersion.where("updated_at > ?", date_window).group("updater_id").having("count(*) > ?", min_changes).pluck(:updater_id)
		end
	end
end
