module BigQuery
  class ArtistVersion < Base
    def count_total(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions] where updater_id = #{user_id} and updated_at >= '#{min_date}'")
    end

    def count_creates(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions] where updater_id = #{user_id} and updated_at >= '#{min_date}' and version = 1")
    end

    def count_name(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions] where updater_id = #{user_id} and updated_at >= '#{min_date}' and name is not null")
    end

    def count_other(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions] where updater_id = #{user_id} and updated_at >= '#{min_date}' and other_names is not null")
    end

    def count_url(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions] where updater_id = #{user_id} and updated_at >= '#{min_date}' and url_string is not null")
    end

    def count_group(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions] where updater_id = #{user_id} and updated_at >= '#{min_date}' and group_name is not null")
    end

    def count_delete(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions] where updater_id = #{user_id} and updated_at >= '#{min_date}' and is_active = false")
    end

    def count_undelete(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.artist_versions] where updater_id = #{user_id} and updated_at >= '#{min_date}' and is_active = true and version > 1")
    end

    def count_wiki(user_id, min_date)
      DanbooruRo::WikiPage.joins("join artists on artists.name = wiki_pages.title").where("wiki_pages.creator_id = ? and wiki_pages.created_at > ?", user_id, min_date).count

      #DanbooruRo::WikiPageVersion.joins("join artist_versions on artist_versions.name = wiki_page_versions.title").where("wiki_page_versions.updater_id = ? and wiki_page_versions.updated_at - artist_versions.updated_at < interval '1 second' and wiki_page_versions.updated_at > ? and artist_versions.updater_id = ?", user_id, min_date, user_id).count
    end
  end
end
