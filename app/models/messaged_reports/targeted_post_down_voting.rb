module MessagedReports
  class TargetedPostDownVoting
    attr_reader :user_id, :post

    Result = Struct.new(:user_id, :jaccard_index, :intersect_count, :union_count) do
      def <=>(rhs)
        rhs.jaccard_index <=> jaccard_index
      end

      def to_json
        [user_id, jaccard_index * 100].to_json
      end
    end

    def initialize(user_id, post_id)
      @user_id = user_id
      @post = DanbooruRo::Post.find(post_id)
    end

    def send_message()
      results = build_report
      uploader_name = DanbooruRo::User.find(post.uploader_id).name

      title = "Targeted voting on posts for #{uploader_name} on post ##{post.id}"
      body = "The following users are suspected of downvoting uploads by #{uploader_name} based on data from post ##{post.id}. In general, you should look for a similarity percentage above 25%.\n\nThe fraction in the parentheses is the number of posts uploaded by #{uploader_name} that were downvoted by the suspect, divided by the count of all the uploads of #{uploader_name} and downvotes of the suspect. This is to normalize the effects of users who many upload a lot, or users who may vote a lot. If every downvote from the suspect was for every upload from the user, then this ratio will be 1. All upload counts are limited to the most recent 90 days.\n\n"

      results.each do |result|
        voter_name = DanbooruRo::User.find(result.user_id).name
        percentage = "%.0f" % result.jaccard_index
        intersect_count = result.intersect_count
        union_count = result.union_count
        body << "* #{voter_name}: #{percentage}\% (#{intersect_count} / #{union_count})\n"
      end

      DanbooruMessenger.new.send_message(user_id, title, body)
    end

    def build_report
      report = Set.new

      y = all_uploads.pluck(:id)
      candidate_voters.each do |voter|
        x = DanbooruRo::PostVote.where(user_id: voter.user_id).where("score < 0").pluck(:post_id)
        intersect, union, jaccard = calculate_jaccard(x, y)
        if jaccard > 0
          report.add(Result.new(voter.user_id, jaccard, intersect, union))
        end
      end

      return report
    end

    def calculate_jaccard(x, y)
      intersect = (x & y).size
      union = x.size + y.size - intersect
      idx = 100 * intersect.to_f / union.to_f
      return [intersect, union, idx]
    end

    def candidate_voters
      DanbooruRo::PostVote.where(post_id: post.id).where("score < 0")
    end

    def all_uploads
      DanbooruRo::Post.where("created_at > ? and uploader_id = ?", 90.days.ago, post.uploader_id)
    end
  end
end
