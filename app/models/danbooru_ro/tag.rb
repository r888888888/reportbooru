module DanbooruRo
  class Tag < Base
    attr_readonly *column_names
    CATEGORIES = ["general", "artist", nil, "copyright", "character"]

    def self.select_category_for(tag_name)
      key = CityHash.hash64(tag_name).to_s(36)
      Rails.cache.fetch("tc:#{key}", expires_in: 1.hour) do
        select_value_sql("SELECT category FROM tags WHERE name = ?", tag_name).to_i
      end
    end

    def self.post_count(name)
      where(name: name).pluck(:post_count).first
    end
  end
end