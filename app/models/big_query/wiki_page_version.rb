module BigQuery
  class WikiPageVersion < Base
    def count_total(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.wiki_page_versions] where updater_id = #{user_id} and updated_at >= '#{min_date}'")
    end

    def count_creates(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.wiki_page_versions] where updater_id = #{user_id} and updated_at >= '#{min_date}' and version = 1")
    end

    def count_title_changes(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.wiki_page_versions] where updater_id = #{user_id} and updated_at >= '#{min_date}' and title is not null")
    end

    def count_other_name_changes(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.wiki_page_versions] where updater_id = #{user_id} and updated_at >= '#{min_date}' and other_names is not null")
    end

    def count_body_changes(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.wiki_page_versions] where updater_id = #{user_id} and updated_at >= '#{min_date}' and body is not null")
    end
  end
end
