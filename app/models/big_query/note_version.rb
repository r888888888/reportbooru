module BigQuery
  class NoteVersion < Base
    def count_total(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.note_versions_flat] where updater_id = #{user_id} and updated_at >= '#{min_date}'")
    end

    def count_creates(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.note_versions_flat] where updater_id = #{user_id} and updated_at >= '#{min_date}' and version = 1")
    end

    def count_edits(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.note_versions_flat] where updater_id = #{user_id} and updated_at >= '#{min_date}' and body is not null and version > 1")
    end

    def count_moves(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.note_versions_flat] where updater_id = #{user_id} and updated_at >= '#{min_date}' and (x is not null or y is not null) and version > 1")
    end

    def count_resizes(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.note_versions_flat] where updater_id = #{user_id} and updated_at >= '#{min_date}' and (width is not null or height is not null) and version > 1")
    end

    def count_deletes(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.note_versions_flat] where updater_id = #{user_id} and updated_at >= '#{min_date}' and is_active = false and version > 1")
    end

    def count_undeletes(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.note_versions_flat] where updater_id = #{user_id} and updated_at >= '#{min_date}' and is_active = true and version > 1")
    end

  end
end
