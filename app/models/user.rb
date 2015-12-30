class User < DanbooruModel
  attr_readonly *column_names

  def self.users_with_favorites_ids(min_count = 500)
    select_values_sql("select id from users where fav_count >= ?", min_count)
  end
end
