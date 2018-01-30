module Reports
  class BuilderPostChanges < PostChanges
    def report_name
      "builder_post_changes"
    end

    def title
      "Builder Post Change"
    end

    def candidates
      builders = DanbooruRo::User.where("level < ?", DanbooruRo::User::Levels::BUILDER).pluck(:id)
      Archive::PostVersion.where("post_versions.updated_at > ? AND post_versions.updater_id in (?)", date_window, builders).group("post_versions.updater_id").having("count(*) > ?", min_changes).pluck(:updater_id)
    end
  end
end