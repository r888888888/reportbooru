class PostVote < DanbooruModel
  attr_readonly *column_names

  def self.unique_user_ids
    select_values_sql("select user_id from post_votes where score > 0 group by user_id having count(*) > 100")
  end

  def self.positive_post_ids(user_id)
    select_values_sql("select post_id from post_votes where score > 0 and user_id = #{user_id.to_i}")
  end
end
