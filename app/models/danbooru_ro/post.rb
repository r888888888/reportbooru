module DanbooruRo
  class Post < Base
    attr_readonly *column_names

    def self.escaped_for_tsquery(s)
      "'#{s.gsub(/\0/, '').gsub(/'/, '\0\0').gsub(/\\/, '\0\0\0\0')}'"
    end

    def self.raw_tag_match(tag)
      where("tag_index @@ to_tsquery('danbooru', E?)", escaped_for_tsquery(tag))
    end

    def self.raw_intersection_tag_match(tags)
      escaped_tags = tags.map {|x| escaped_for_tsquery(x)}.join(" & ")
      where("tag_index @@ to_tsquery('danbooru', E?)", escaped_tags)
    end

    def self.partition(min_date, max_date)
      where("created_at between ? and ?", min_date, max_date).group("date_trunc('day', created_at)").select("date_trunc('day', created_at) as date, count(*) as post_count").order("date_trunc('day', created_at)")
    end

    def self.favorited_user_ids(post_id)
      fav_string = select_value_sql("select fav_string from posts where id = ?", post_id)
      user_ids = fav_string.scan(/\d+/)
    end

    def self.estimate_post_id(date)
      # we don't have the timestamp from the favorites query so try to
      # guess the uploaded post id based on the date

      # 0  : 1
      # 1  : 41854
      # 2  : 122253
      # 3  : 253308
      # 4  : 459340
      # 5  : 676576
      # 6  : 922108
      # 7  : 1172251
      # 8  : 1425013
      # 9  : 1693611
      # 10 : 2020092
      # y = 13303.93124x^2 + 75291.75128x - 43332.07692

      base = Date.civil(2005, 5, 24)
      x = (date - base) / 365.0
      [13303.93124 * x**2 + 75291.75128 * x - 43332.07692, 0].max.to_i
    end
  end

end