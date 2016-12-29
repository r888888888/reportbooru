module MessagedReports
  class MissingTags
    def min_uploads
      10
    end

    def date_window
      1.week.ago
    end

    def build
      candidates.each do |user_id|
        post_ids = post_ids_for(user_id)
        bq = BigQuery::PostVersion.new(date_window)
        puts bq.aggregate_missing_tags(user_id, post_ids).inspect
      end
    end

    def post_ids_for(user_id)
      DanbooruRo::Post.where("created_at >= ? and uploader_id = ?", date_window, user_id).pluck("id")
    end

    def candidates
      DanbooruRo::Post.where("created_at >= ? ", date_window).group("users.id").having("count(*) > ?", min_uploads).pluck("distinct(users.id)")
    end
  end
end
