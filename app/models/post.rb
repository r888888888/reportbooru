class Post < DanbooruModel
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
end
