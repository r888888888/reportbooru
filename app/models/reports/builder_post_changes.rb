module Reports
  class BuilderPostChanges < PostChanges
    def report_name
      "builder_post_changes"
    end

    def title
      "Builder Post Change"
    end

    def candidates
      Archive::PostVersion.where("post_versions.updated_at > ? AND users.level >= ?", date_window, DanbooruRo::User::Levels::BUILDER).joins("JOIN users ON post_versions.updater_id = users.id").group("post_versions.updater_id").having("count(*) > ?", min_changes).pluck(:updater_id)
    end
  end
end