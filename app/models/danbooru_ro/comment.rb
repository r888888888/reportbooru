module DanbooruRo
  class Comment < Base
    attr_readonly *column_names
  end
end
