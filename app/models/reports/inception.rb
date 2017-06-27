module Reports
  # this builds several csv files for the inception image classifier service.
  # it finds posts with one character, and a random subset of general tags.
  class Inception
    def date_window
      3.months.ago
    end

    def find_one_character_posts
      DanbooruRo::Post.where("created_at > ? and tag_count_character = 1", date_window)
    end
  end
end
