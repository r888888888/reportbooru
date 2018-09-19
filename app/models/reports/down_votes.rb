module Reports
  class DownVotes < Base
    def initialize
      @candidates = self.candidates()
    end

    def version
      2
    end

    def min_votes
      10
    end

    def date_window
      90.days.ago
    end

    def report_name
      "down_votes"
    end

    def sort_key
      :down_votes
    end
    
    def html_template
      return <<-EOS
%html
  %head
    %title Post Down Voters Report
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
      %caption Post Down Voters (over past ninety days, minimum count is #{min_votes})
      %thead
        %tr
          %th User
          %th Down Votes
          %th{:title => "Sorted by percentage"} Targeted Uploaders
          %th{:title => "Across all down votes, not just this user, scored using Jaccard index"} Similar Voters
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:down_votes]
            %td
              %ul
                - datum[:targets].each do |target_id, score|
                  %li
                    = DanbooruRo::User.find(target_id).name
                    = ": " + ("%0.0f%" % score)
            %td
              %ul
                - datum[:similar].each do |user_id, score|
                  %li
                    = DanbooruRo::User.find(user_id).name
                    = ": " + ("%0.0f%" % score)
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}"
EOS
    end

    def targets(voter_id)
      mapping = DanbooruRo::Post.where("post_votes.created_at > ? AND post_votes.user_id = ? AND post_votes.score < 0", date_window, voter_id).joins("JOIN post_votes ON posts.id = post_votes.post_id").group("posts.uploader_id").having("count(*) > 1").count
      total = DanbooruRo::PostVote.where("created_at > ? and user_id = ? and score < 0", date_window, voter_id).count.to_f
      mapping = mapping.to_a.map do |uploader_id, count|
        [uploader_id, 100 * count.to_f / total]
      end
      mapping = mapping.sort_by {|x| x[1]}.last(3).reverse
    end

    def similar(user_id)
      scores = {}
      user_votes = Set.new(DanbooruRo::PostVote.where("created_at > ? and score < 0 and user_id = ?", date_window, user_id).pluck(:post_id))
      @candidates.each do |candidate_id|
        next if candidate_id == user_id

        candidate_votes = Set.new(DanbooruRo::PostVote.where("created_at > ? and score < 0 and user_id = ?", date_window, candidate_id).pluck(:post_id))
        intersection = user_votes & candidate_votes
        jaccard_index = 100 * (intersection.size.to_f) / (user_votes.size + candidate_votes.size - intersection.size).to_f
        scores[candidate_id] = jaccard_index
      end
      scores.to_a.sort_by {|x| x[1]}.last(3).reverse
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)

      return {
        id: user.id,
        name: user.name,
        down_votes: DanbooruRo::PostVote.where("created_at > ? and score < 0 and user_id = ?", date_window, user.id).count,
        targets: targets(user_id),
        similar: similar(user_id)
      }
    end
    
    def candidates
      DanbooruRo::PostVote.where("created_at > ? and score < 0", date_window).group("user_id").having("count(*) >= ?", min_votes).pluck(:user_id)
    end
  end
end
