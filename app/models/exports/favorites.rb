module Exports
  class Favorites
    BATCH_SIZE = 10000
    SCHEMA = {
      id: {type: "INTEGER"},
      user_id: {type: "INTEGER"},
      post_id: {type: "INTEGER"}
    }

    attr_reader :redis, :logger, :gbq

    def initialize(redis, logger, gbq)
      @redis = redis
      @logger = logger
      @gbq = gbq
    end

    def get_last_exported_id
      redis.get("favorites-id").to_i
    end

    def create_table
      begin
        gbq.create_table("favorites", SCHEMA, enable_partitioning: true)
      rescue Google::Apis::ClientError
      end
    end

    def execute
      begin
        create_table

        last_id = get_last_exported_id
        next_id = last_id + BATCH_SIZE
        store_id = last_id
        batch = []
        DanbooruRo::Favorite.where("id > ? and id <= ?", last_id, next_id).find_each do |fav|
          batch << {id: fav.id, user_id: fav.user_id, post_id: fav.post_id}

          if fav.id > store_id
            store_id = fav.id
          end
        end

        if batch.any?
          logger.info "favorite: inserting #{last_id}..#{store_id}"
          partition_timestamp = Time.now.strftime("%Y%m%d")
          result = gbq.insert("favorites$#{partition_timestamp}", batch)
          if result["insertErrors"]
            logger.error result.inspect
          else
            redis.set("favorites-id", store_id)
          end
        end

      rescue Exception => e
        logger.error "error: #{e}"
      end
    end
  end
end
