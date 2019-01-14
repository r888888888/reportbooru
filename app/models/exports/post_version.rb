module Exports
  class PostVersion
    BATCH_SIZE = 100
    SCHEMA = {
      id: {type: "INTEGER"},
      updated_at: {type: "TIMESTAMP"},
      post_id: {type: "INTEGER"},
      tags: {type: "STRING"},
      added_tags: {type: "STRING"},
      removed_tags: {type: "STRING"},
      rating: {type: "STRING"},
      parent_id: {type: "INTEGER"},
      source: {type: "STRING"},
      updater_id: {type: "INTEGER"},
      updater_ip_addr: {type: "STRING"}
    }

    attr_reader :redis, :logger, :gbq

    def initialize(redis, logger, gbq)
      @redis = redis
      @logger = logger
      @gbq = gbq
    end

    def get_last_exported_id
      redis.get("post-version-exporter-id").to_i
    end

    def find_previous(version)
      version.previous
    end

    def create_table
      begin
        gbq.create_table("post_versions", SCHEMA, enable_partitioning: true)
      rescue Google::Apis::ClientError
      end
    end

    def calculate_diff(older, newer)
      if older
        older_tags = older.tags.scan(/\S+/)
        older_tags << "rating:#{older.rating}" if older.rating.present?
        older_tags << "parent:#{older.parent_id}" if older.parent_id.present?
        older_tags << "source:#{older.source}" if older.source.present?
      else
        older_tags = []
      end

      newer_tags = newer.tags.scan(/\S+/)
      newer_tags << "rating:#{newer.rating}" if newer.rating.present?
      newer_tags << "parent:#{newer.parent_id}" if newer.parent_id.present?
      newer_tags << "source:#{newer.source}" if newer.source.present?

      added_tags = newer_tags - older_tags
      removed_tags = older_tags - newer_tags

      return {
        :added_tags => added_tags,
        :removed_tags => removed_tags
      }
    end

    def execute
      create_table

      last_id = get_last_exported_id
      next_id = last_id + BATCH_SIZE
      store_id = last_id
      batch = []
      Archive::PostVersion.where("id > ? and id <= ? and updated_at < ?", last_id, next_id, 70.minutes.ago).find_each do |version|
        previous = find_previous(version)
        diff = calculate_diff(previous, version)
        hash = {
          "id" => version.id,
          "updated_at" => version.updated_at,
          "post_id" => version.post_id,
          "tags" => version.tags,
          "added_tags" => diff[:added_tags].join(" "),
          "removed_tags" => diff[:removed_tags].join(" "),
          "rating" => version.rating,
          "parent_id" => version.parent_id,
          "source" => version.source,
          "updater_id" => version.updater_id,
          "updater_ip_addr" => version.updater_ip_addr.to_s
        }
        batch << hash
        if version.id > store_id
          store_id = version.id
        end
      end

      if batch.any?
        logger.info "post versions: inserting #{last_id}..#{store_id}"
        result = gbq.insert("post_versions", batch)
        if result["insertErrors"]
          logger.error result.inspect
        else
          redis.set("post-version-exporter-id", store_id)
        end
      end
    end
  end
end
