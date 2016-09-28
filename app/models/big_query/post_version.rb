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
      query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id}")
    end

    def count_added(user_id)
      query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and added_tag is not null")
    end

    def count_removed(user_id)
      query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and removed_tag is not null")
    end

    def count_artist_added(user_id)
      query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] join [danbooru_#{Rails.env}.tags] on post_versions_flat.added_tag = tags.name where post_versions_flat.updater_id = #{user_id} and post_versions_flat.added_tag is not null and tags.category = 1")
    end

    def count_character_added(user_id)
      query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] join [danbooru_#{Rails.env}.tags] on post_versions_flat.added_tag = tags.name where post_versions_flat.updater_id = #{user_id} and post_versions_flat.added_tag is not null and tags.category = 4")
    end

    def count_copyright_added(user_id)
      query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] join [danbooru_#{Rails.env}.tags] on post_versions_flat.added_tag = tags.name where post_versions_flat.updater_id = #{user_id} and post_versions_flat.added_tag is not null and tags.category = 3")
    end

    def count_rating_changed(user_id)
      query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and removed_tag like 'rating:%'")
    end

    def count_source_changed(user_id)
      query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where updater_id = #{user_id} and removed_tag like 'source:%'")
    end
  end
end
