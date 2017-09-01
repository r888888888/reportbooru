require 'csv'

module Exports
  class Ccs
    def self.build
      n = 6.months.ago
      CSV.open("/var/www/reportbooru/shared/public/exports/posts_chars.csv", "wb") do |csv|
        csv << ["id", "md5", "url", "tags"]
        DanbooruRo::Post.where("tag_count_character <= 2 and created_at > ?", n).find_each do |post|
          if (post.file_ext == "jpg" || post.file_ext == "png") && (post.tag_count_character == 1 || post.tag_string =~ /\dgirl|\dboy/) && post.tag_string !~ /comic|monochrome/
            tags =[]
            post.tag_array.each do |tag|
              if DanbooruRo::Tag.select_category_for(tag) == 4 && !DanbooruRo::TagImplication.where(antecedent_name: tag).exists?
                tags << tag
              end
            end
            tags.each do |tag|
              if post.image_width.to_i > 850
                large_file_path = "sample/sample-#{post.md5}.jpg"
              else
                large_file_path = "#{post.md5}.#{post.file_ext}"
              end
              csv << [post.id, post.md5, "https://s3.amazonaws.com/danbooru/#{large_file_path}", tag]
            end
          end
        end
      end
    end
  end
end
