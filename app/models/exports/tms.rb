require 'csv'

module Exports
  class Tms
    def self.build
      n = 4.months.ago
      CSV.open("/var/www/reportbooru/shared/public/exports/tags.csv", "wb") do |csv|
        csv << ["id", "tags"]
        DanbooruRo::Post.where("created_at > ?", n).find_each do |post|
          csv << [post.id, post.tag_string]
        end
      end
    end
  end
end
