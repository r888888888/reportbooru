module BigQuery
  class PostVersion < Base
    def find_removed(tag)
      tag = escape(tag)
      query("select id, post_id, updated_at, updater_id, updater_ip_addr, tags, added_tags, removed_tags, parent_id, rating, source from [danbooru_#{Rails.env}.post_versions] where removed_tags contains \"#{tag}\" order by updated_at desc limit 1000")
    end

    def find_added(tag)
      tag = escape(tag)
      query("select id, post_id, updated_at, updater_id, updater_ip_addr, tags, added_tags, removed_tags, parent_id, rating, source from [danbooru_#{Rails.env}.post_versions] where added_tags contains \"#{tag}\" order by updated_at desc limit 1000")
    end
  end
end
