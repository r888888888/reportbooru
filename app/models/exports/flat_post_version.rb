module Exports
  class FlatPostVersion
    BATCH_SIZE = 100
    SCHEMA = {
      version_id: {type: "INTEGER"},
      version: {type: "INTEGER"},
      updated_at: {type: "TIMESTAMP"},
      post_id: {type: "INTEGER"},
      added_tag: {type: "STRING"},
      removed_tag: {type: "STRING"},
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
      redis.get("flat-post-version-exporter-id-part").to_i
    end

    def find_previous(version)
      version.previous
    end

    def find_version_number(version)
      version.version
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

    def create_table
      begin
        gbq.create_table("post_versions_flat_part", SCHEMA, enable_partitioning: true)
      rescue Google::Apis::ClientError
      end
    end

    def execute
      create_table

      begin
        last_id = get_last_exported_id
        next_id = last_id + BATCH_SIZE
        store_id = last_id
        batch = []
        Archive::PostVersion.where("id > ? and id <= ? and updated_at < ?", last_id, next_id, 70.minutes.ago).find_each do |version|
          previous = find_previous(version)
          diff = calculate_diff(previous, version)
          vnum = find_version_number(version)
          
          diff[:added_tags].each do |added_tag|
            hash = {
              "version_id" => version.id,
              "version" => vnum,
              "updated_at" => version.updated_at,
              "post_id" => version.post_id,
              "added_tag" => added_tag,
              "updater_id" => version.updater_id,
              "updater_ip_addr" => version.updater_ip_addr.to_s
            }
            batch << hash
          end

          diff[:removed_tags].each do |removed_tag|
            hash = {
              "version_id" => version.id,
              "version" => vnum,
              "updated_at" => version.updated_at,
              "post_id" => version.post_id,
              "removed_tag" => removed_tag,
              "updater_id" => version.updater_id,
              "updater_ip_addr" => version.updater_ip_addr.to_s
            }
            batch << hash
          end

          if diff[:added_tags].empty? && diff[:removed_tags].empty?
            hash = {
              "version_id" => version.id,
              "version" => vnum,
              "updated_at" => version.updated_at,
              "post_id" => version.post_id,
              "updater_id" => version.updater_id,
              "updater_ip_addr" => version.updater_ip_addr.to_s
            }
            batch << hash
          end

          if version.id > store_id
            store_id = version.id
          end
        end

        if batch.any?
          logger.info "flat post versions: inserting #{last_id}..#{store_id}"
          partition_timestamp = batch[0]["updated_at"].strftime("%Y%m%d")
          result = gbq.insert("post_versions_flat_part$#{partition_timestamp}", batch)
          if result["insertErrors"]
            logger.error result.inspect
          else
            redis.set("flat-post-version-exporter-id-part", store_id)
          end
        end
      rescue PG::ConnectionBad, PG::UnableToSend
        raise
      rescue Exception => e
        logger.error "#{e.class}"
        logger.error "error: #{e.to_s}"
        e.backtrace.each do |line|
          logger.error line
        end

      end
    end
  end
end
