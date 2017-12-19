module MessagedReports
  class MissingTags
    def min_uploads
      10
    end

    def date_window
      15.days.ago
    end

    def metatags
      @metatags ||= DanbooruRo::Tag.where(category: 5).pluck(:name)
    end

    def send_messages
      candidates.each do |user_id|
        post_ids = post_ids_for(user_id)
        bq = BigQuery::PostVersion.new(date_window)
        missing = bq.aggregate_missing_tags(user_id, post_ids)
        missing = missing.reject {|x| metatags.include?(x[0])} if missing

        if missing
          title = "You have tags that are underused on your uploads"
          body = "The following tags were added by other users to your uploads. Consider using them in the future.\n\n"
          missing.each do |x|
            body << "* [[" + x[0] + "]]\n"
          end

          DanbooruMessenger.new.send_message(user_id, title, body)
        end
      end
    end

    def post_ids_for(user_id)
      DanbooruRo::Post.where("created_at >= ? and uploader_id = ?", date_window, user_id).pluck("id")
    end

    def candidates
      DanbooruRo::Post.where("created_at >= ? ", date_window).group("uploader_id").having("count(*) > ?", min_uploads).pluck("uploader_id")
    end
  end
end
