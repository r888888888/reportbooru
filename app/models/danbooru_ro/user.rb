module DanbooruRo
  class User < Base
    module Levels
      BLOCKED = 10
      MEMBER = 20
      GOLD = 30
      PLATINUM = 31
      BUILDER = 32
      JANITOR = 35
      MODERATOR = 40
      ADMIN = 50
    end

    attr_readonly *column_names

    def self.users_with_favorites_ids(min_count = 500)
      select_values_sql("select id from users where fav_count >= ?", min_count)
    end
  end
end
