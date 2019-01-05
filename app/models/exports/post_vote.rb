module Exports
  class PostVote
    BATCH_SIZE = 1000
    SCHEMA = {
      id: {type: "INTEGER"},
      post_id: {type: "INTEGER"},
      user_id: {type: "INTEGER"},
      score: {type: "INTEGER"},
      created_at: {type: "TIMESTAMP"}
    }

    attr_reader :redis, :logger, :gbq

    def initialize(redis, logger, gbq)
      @redis = redis
      @logger = logger
      @gbq = gbq
    end

    def get_last_exported_id
      redis.get("post-votes-id").to_i
    end

    def create_table
      begin
        gbq.create_table("post_votes", SCHEMA, enable_partitioning: true)
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
        DanbooruRo::PostVote.where("created_at >= ? and id > ? and id <= ?", 30.days.ago, last_id, next_id).find_each do |vote|
          batch << {id: vote.id, user_id: vote.user_id, post_id: vote.post_id, score: vote.score, created_at: vote.created_at}

          if vote.id > store_id
            store_id = vote.id
          end
        end

        if batch.any?
          logger.info "post vote: inserting #{last_id}..#{store_id}"
          partition_timestamp = batch[0][:created_at].strftime("%Y%m%d")
          result = gbq.insert("post_votes$#{partition_timestamp}", batch)
          if result["insertErrors"]
            logger.error result.inspect
          else
            redis.set("post-votes-id", store_id)
          end
        end

      rescue PG::ConnectionBad, PG::UnableToSend
        raise
      rescue Exception => e
        logger.error "error: #{e}"
      end
    end
  end
end
