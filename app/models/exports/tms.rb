require 'csv'

module Exports
  class Tms
    def self.build
      n = 3.months.ago
      CSV.open("/var/www/reportbooru/shared/public/exports/tags.csv", "wb") do |csv|
        csv << ["id", "artists", "characters", "copyrights", "general"]
        DanbooruRo::Post.where("created_at > ?", n).find_each do |post|
          tags = post.tag_array
          gen_tags = []
          art_tags = []
          char_tags = []
          copy_tags = []
          tags.each do |tag|
            category = DanbooruRo::Tag.select_category_for(tag).to_i
            case Tag::CATEGORIES[category]
            when "artist"
              art_tags << tag

            when "character"
              char_tags << tag

            when "copyright"
              copy_tags << tag

            else
              gen_tags << tag
            end
          end
          csv << [post.id, art_tags.join(" "), char_tags.join(" "), copy_tags.join(" "), gen_tags.join(" ")]
        end
      end
    end
  end
end
