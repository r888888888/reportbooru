module BigQuery
  class WikiPageVersion < Base
    def count_total(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.wiki_page_versions_part] where _partitiontime >= '#{part_s}' and updater_id = #{user_id} and updated_at >= '#{date_s}'")
    end

    def count_creates(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.wiki_page_versions_part] where _partitiontime >= '#{part_s}' and updater_id = #{user_id} and updated_at >= '#{date_s}' and version = 1")
    end

    def count_title_changes(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.wiki_page_versions_part] where _partitiontime >= '#{part_s}' and updater_id = #{user_id} and updated_at >= '#{date_s}' and title is not null")
    end

    def count_other_name_changes(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.wiki_page_versions_part] where _partitiontime >= '#{part_s}' and updater_id = #{user_id} and updated_at >= '#{date_s}' and other_names is not null")
    end

    def count_body_changes(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.wiki_page_versions_part] where _partitiontime >= '#{part_s}' and updater_id = #{user_id} and updated_at >= '#{date_s}' and body is not null")
    end
  end
end
