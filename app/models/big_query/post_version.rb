module BigQuery
  class PostVersion < Base
    TRANSLATOR_TAGS = %w(translated check_translation partially_translated translation_request commentary check_commentary commentary_request)
    TRANSIENT_TAGS = TRANSLATOR_TAGS + %w(character_request copyright_request artist_request tagme annotated partially_annotated check_my_note check_pixiv_source)
    TRANSIENT_TAGS_SQL = TRANSIENT_TAGS.map {|x| "'#{x}'"}.join(', ')

    def find_removed(tag)
      tag = escape(tag)
      query("select id, post_id, updated_at, updater_id, updater_ip_addr, tags, added_tags, removed_tags, parent_id, rating, source from [danbooru_#{Rails.env}.post_versions] where regexp_match(removed_tags, \"(?:^| )#{tag}(?:$| )\") order by updated_at desc limit 1000")
    end

    def find_added(tag)
      tag = escape(tag)
      query("select id, post_id, updated_at, updater_id, updater_ip_addr, tags, added_tags, removed_tags, parent_id, rating, source from [danbooru_#{Rails.env}.post_versions] where regexp_match(added_tags, \"(?:^| )#{tag}(?:$| )\") order by updated_at desc limit 1000")
    end

    def count_changes(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and updated_at >= '#{date_s}' and added_tag not in (#{TRANSIENT_TAGS_SQL}) and removed_tag not in (#{TRANSIENT_TAGS_SQL})")
    end

    def count_added(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and added_tag is not null and updated_at >= '#{date_s}' and added_tag not in (#{TRANSIENT_TAGS_SQL})")
    end

    def count_removed(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and removed_tag is not null and updated_at >= '#{date_s}' and removed_tag not in (#{TRANSIENT_TAGS_SQL})")
    end

    def count_artist_added(user_id)
      get_count query("select count(*) from (select added_tag from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and added_tag is not null and updated_at >= '#{date_s}') pvf cross join [danbooru_#{Rails.env}.tags] t on t.name = pvf.added_tag and t.category = 1")
    end

    def count_artist_added_v1(user_id)
      get_count query("select count(*) from (select added_tag from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and added_tag is not null and updated_at >= '#{date_s}' and version = 1) pvf cross join [danbooru_#{Rails.env}.tags] t on t.name = pvf.added_tag and t.category = 1")
    end

    def count_character_added(user_id)
      get_count query("select count(*) from (select added_tag from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and added_tag is not null and updated_at >= '#{date_s}') pvf cross join [danbooru_#{Rails.env}.tags] t on t.name = pvf.added_tag and t.category = 4")
    end

    def count_character_added_v1(user_id)
      get_count query("select count(*) from (select added_tag from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and added_tag is not null and updated_at >= '#{date_s}' and version = 1) pvf cross join [danbooru_#{Rails.env}.tags] t on t.name = pvf.added_tag and t.category = 4")
    end

    def count_copyright_added(user_id)
      get_count query("select count(*) from (select added_tag from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and added_tag is not null and updated_at >= '#{date_s}') pvf cross join [danbooru_#{Rails.env}.tags] t on t.name = pvf.added_tag and t.category =3")
    end

    def count_copyright_added_v1(user_id)
      get_count query("select count(*) from (select added_tag from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and added_tag is not null and updated_at >= '#{date_s}' and version = 1) pvf cross join [danbooru_#{Rails.env}.tags] t on t.name = pvf.added_tag and t.category = 3")
    end

    def count_general_added(user_id)
      get_count query("select count(*) from (select added_tag from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and added_tag is not null and updated_at >= '#{date_s}') pvf cross join [danbooru_#{Rails.env}.tags] t on t.name = pvf.added_tag and t.category = 0 and t.name not in (#{TRANSIENT_TAGS_SQL})")
    end

    def count_general_added_v1(user_id)
      get_count query("select count(*) from (select added_tag from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and added_tag is not null and updated_at >= '#{date_s}' and version = 1) pvf cross join [danbooru_#{Rails.env}.tags] t on t.name = pvf.added_tag and t.category = 0 and t.name not in (#{TRANSIENT_TAGS_SQL})")
    end

    def count_any_added_v1(user_id)
      get_count query("select count(*) from (select added_tag from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and added_tag is not null and updated_at >= '#{date_s}' and version = 1) pvf cross join [danbooru_#{Rails.env}.tags] t on t.name = pvf.added_tag and t.name not in (#{TRANSIENT_TAGS_SQL})")
    end

    def count_rating_changed(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and regexp_match(removed_tag, r'^rating:') and updated_at >= '#{date_s}'")
    end

    def count_source_changed(user_id)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and regexp_match(removed_tag, r'^source:') and updated_at >= '#{date_s}'")
    end

    def translator_tag_candidates(min_changes)
      tag_subquery = TRANSLATOR_TAGS.map {|x| "'#{x}'"}.join(", ")
      resp = query("select updater_id from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and added_tag in (#{tag_subquery}) or removed_tag in (#{tag_subquery}) and updated_at >= '#{date_s}' group by updater_id having count(*) > #{min_changes}")

      if resp["rows"]
        resp["rows"].map {|x| x["f"][0]["v"]}.select {|x| x.is_a?(String)}
      else
        []
      end
    end

    def count_tag_added(user_id, tag)
      es = escape(tag)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat_part] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and added_tag = '#{es}' and updated_at >= '#{date_s}' and added_tag not in (#{TRANSIENT_TAGS_SQL})")
    end

    def count_tag_removed(user_id, tag)
      es = escape(tag)
      get_count query("select count(*) from [danbooru_#{Rails.env}.post_versions_flat] where _partitiontime >= timestamp('#{part_s}') and updater_id = #{user_id} and removed_tag = '#{es}' and updated_at >= '#{date_s}' and removed_tag not in (#{TRANSIENT_TAGS_SQL})")
    end
  end
end
