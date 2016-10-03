module DanbooruRo
  class Favorite < Base
    attr_readonly *column_names
    scope :for_user, lambda {|user_id| where("user_id % 100 = #{user_id.to_i % 100} and user_id = #{user_id.to_i}")}

    def self.post_ids(user_id)
      select_values_sql("select post_id from favorites where user_id % 100 = #{user_id.to_i % 100} and user_id = #{user_id.to_i}")
    end
  end
end
