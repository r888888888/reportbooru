module BigQuery
  class ArtistVersion < Base
    def count_total(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and updated_at >= '#{date_s}'")
    end

    def count_creates(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and updated_at >= '#{date_s}' and version = 1")
    end

    def count_name(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and updated_at >= '#{date_s}' and name is not null")
    end

    def count_other(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and updated_at >= '#{date_s}' and other_names is not null")
    end

    def count_url(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and updated_at >= '#{date_s}' and url_string is not null")
    end

    def count_group(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and updated_at >= '#{date_s}' and group_name is not null")
    end

    def count_delete(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and updated_at >= '#{date_s}' and is_active = false")
    end

    def count_undelete(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and updated_at >= '#{date_s}' and is_active = true and version > 1")
    end

    def count_wiki(user_id)
      DanbooruRo::WikiPage.joins("join artists on artists.name = wiki_pages.title").where("wiki_pages.creator_id = ? and wiki_pages.created_at > ?", user_id, date_s).count

      #DanbooruRo::WikiPageVersion.joins("join artist_versions on artist_versions.name = wiki_page_versions.title").where("wiki_page_versions.updater_id = ? and wiki_page_versions.updated_at - artist_versions.updated_at < interval '1 second' and wiki_page_versions.updated_at > ? and artist_versions.updater_id = ?", user_id, date_s, user_id).count
    end
  end
end
