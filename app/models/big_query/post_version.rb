module BigQuery
  class PostVersion < Base
    def find_removed(tag)
      tag = escape(tag)
      query("select id, post_id, updated_at, updater_id, updater_ip_addr, tags, added_tags, removed_tags, parent_id, rating, source from [danbooru_#{Rails.env}.post_versions] where regexp_match(removed_tags, \"(?:^| )#{tag}(?:$| )\") order by updated_at desc limit 1000")
    end

    def find_added(tag)
      tag = escape(tag)
      query("select id, post_id, updated_at, updater_id, updater_ip_addr, tags, added_tags, removed_tags, parent_id, rating, source from [danbooru_#{Rails.env}.post_versions] where regexp_match(added_tags, \"(?:^| )#{tag}(?:$| )\") order by updated_at desc limit 1000")
    end

    def count_changes(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id}")
    end

    def count_added(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and added_tag is not null")
    end

    def count_removed(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and removed_tag is not null")
    end

    def count_artist_added(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 1")
    end

    def count_artist_added_v1(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 1 and pvf.version = 1 and pvf.updated_at >= '#{min_date}'")
    end

    def count_character_added(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 4")
    end

    def count_character_added_v1(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 4 and pvf.version = 1 and pvf.updated_at >= '#{min_date}'")
    end

    def count_copyright_added(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 3")
    end

    def count_copyright_added_v1(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 3 and pvf.version = 1 and pvf.updated_at >= '#{min_date}'")
    end

    def count_general_added_v1(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf join [danbooru_#{Rails.env}.tags] as t on pvf.added_tag = t.name where pvf.updater_id = #{user_id} and pvf.added_tag is not null and t.category = 0 and pvf.version = 1 and pvf.updated_at >= '#{min_date}'")
    end

    def count_any_added_v1(user_id, min_date)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] as pvf where pvf.updater_id = #{user_id} and pvf.added_tag is not null and pvf.version = 1 and pvf.updated_at >= '#{min_date}'")
    end

    def count_rating_changed(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and regexp_match(removed_tag, r'^rating:')")
    end

    def count_source_changed(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and regexp_match(removed_tag, r'^source:')")
    end

    def get_count(resp)
      resp["rows"][0]["f"][0]["v"]
    rescue
      0
    end
  end
end
