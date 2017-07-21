module Exports
  class Ccs
    def self.build
      n = 6.months.ago
      CSV.open("/var/www/reportbooru/shared/public/exports/posts_chars.csv", "wb") do |csv|
        csv << ["id", "md5", "url", "tags"]
        DanbooruRo::Post.where("tag_count_character = 1 and created_at > ?", n).find_each do |post|
          if (post.file_ext == "jpg" || post.file_ext == "png") && post.tag_string !~ /comic|monochrome/
            tags =[]
            post.tag_array.each do |tag|
              if DanbooruRo::Tag.select_category_for(tag) == 4
                chartags << tag
              end
            end
            csv << [post.id, post.md5, "https://s3.amazonaws.com/danbooru" + post.large_file_url.sub(/\/data/, ""), tags.join(" ")]
          end
        end
      end
    end
  end
end
