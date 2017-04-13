module Reports
	class SuperVoters < Base
		def version
			1
		end

    def report_name
      "super_voters"
    end

    def sort_key
      :total
    end

    def html_template
      return <<-EOS
%html
  %head
    %title Super Voter Report
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
      %caption Super voters (over past thirty days)
      %thead
        %tr
          %th User
          %th Level
          %th{:title => "Total count of votes"} Tot Votes
          %th{:title => "Count of up votes"} Pos Votes
          %th{:title => "Count of down votes"} Neg Votes
          %th{:title => "Median score of up voted posts"} Med Pos Score
          %th{:title => "Percentage of up votes on safe posts"} S
          %th{:title => "Percentage of up votes on questionable posts"} Q
          %th{:title => "Percentage of up votes on explicit posts"} E
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:level_string]
            %td= datum[:total]
            %td= datum[:pos_votes]
            %td= datum[:neg_votes]
            %td= datum[:med_score]
            %td= datum[:safe]
            %td= datum[:questionable]
            %td= datum[:explicit]
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}"
EOS
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      total = DanbooruRo::PostVote.where("created_at >= ? and user_id = ?", date_window, user_id).count
      pos_votes = DanbooruRo::PostVote.where("created_at >= ? and user_id = ? and score > 0", date_window, user_id).count
      neg_votes = DanbooruRo::PostVote.where("created_at >= ? and user_id = ? and score < 0", date_window, user_id).count
      med_score = DanbooruRo::Post.select_value_sql("select percentile_cont(0.50) within group (order by posts.score) from posts join post_votes on post_votes.post_id = posts.id where post_votes.created_at >= ? and post_votes.user_id = ? and post_votes.score > 0", date_window, user_id).to_i
      safe = DanbooruRo::PostVote.where("post_votes.created_at > ? and post_votes.user_id = ? and post_votes.score > 0", date_window, user_id).joins(:post).where("posts.rating = ?", "s").count
      questionable = DanbooruRo::PostVote.where("post_votes.created_at > ? and post_votes.user_id = ? and post_votes.score > 0", date_window, user_id).joins(:post).where("posts.rating = ?", "q").count
      explicit = DanbooruRo::PostVote.where("post_votes.created_at > ? and post_votes.user_id = ? and post_votes.score > 0", date_window, user_id).joins(:post).where("posts.rating = ?", "e").count
      post_count = safe + questionable + explicit
      safe = "%d%%" % (100 * safe.to_f / post_count.to_f)
      questionable = "%d%%" % (100 * questionable.to_f / post_count.to_f)
      explicit = "%d%%" % (100 * explicit.to_f / post_count.to_f)

      return {
        id: user.id,
        name: user.name,
        level: user.level,
        level_string: user.level_string,
        total: total,
        pos_votes: pos_votes,
        neg_votes: neg_votes,
        med_score: med_score,
        safe: safe,
        questionable: questionable,
        explicit: explicit
      }
    end

		def candidates
			DanbooruRo::SuperVoter.pluck(:user_id)
		end
	end
end
