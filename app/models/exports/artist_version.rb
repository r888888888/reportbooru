module Exports
  class ArtistVersion
    BATCH_SIZE = 5000
    SCHEMA = {
      version_id: {type: "INTEGER"},
      version: {type: "INTEGER"},
      created_at: {type: "TIMESTAMP"},
      updated_at: {type: "TIMESTAMP"},
      updater_id: {type: "INTEGER"},
      artist_id: {type: "INTEGER"},
      name: {type: "STRING"},
      updater_ip_addr: {type: "STRING"},
      is_active: {type: "BOOLEAN"},
      other_names: {type: "STRING"},
      group_name: {type: "STRING"},
      url_string: {type: "STRING"},
      is_banned: {type: "BOOLEAN"}
    }

    attr_reader :redis, :logger, :gbq

    def initialize(redis, logger, gbq)
      @redis = redis
      @logger = logger
      @gbq = gbq
    end

    def get_last_exported_id
      redis.get("artist-version-exporter-id-part").to_i
    end

    def find_previous(version)
      DanbooruRo::ArtistVersion.where("artist_id = ? and updated_at < ?", version.artist_id, version.updated_at).order("updated_at desc, id desc").first
    end

    def find_version_number(version)
      1 + DanbooruRo::ArtistVersion.where("artist_id = ? and updated_at < ?", version.artist_id, version.updated_at).count
    end

    def calculate_diff(a, b)
      changes = {}

      if a.nil? || a.name != b.name
        changes[:name] = b.name
      end

      if a.nil? || a.is_active != b.is_active
        changes[:is_active] = b.is_active
      end

      if a.nil? || a.other_names != b.other_names
        changes[:other_names] = b.other_names
      end

      if a.nil? || a.group_name != b.group_name
        changes[:group_name] = b.group_name
      end

      if a.nil? || a.url_string != b.url_string
        changes[:url_string] = b.url_string
      end

      if a.nil? || a.is_banned != b.is_banned
        changes[:is_banned] = b.is_banned
      end

      return changes
    end

    def create_table
      begin
        gbq.create_table("artist_versions_part", SCHEMA, enable_partitioning: true)
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
        DanbooruRo::ArtistVersion.where("id > ? and id <= ? and updated_at < ?", last_id, next_id, 70.minutes.ago).find_each do |version|
          previous = find_previous(version)
          diff = calculate_diff(previous, version)
          diff[:version_id] = version.id
          diff[:version] = find_version_number(version)
          diff[:created_at] = version.created_at
          diff[:updated_at] = version.updated_at
          diff[:artist_id] = version.artist_id
          diff[:updater_id] = version.updater_id
          diff[:updater_ip_addr] = version.updater_ip_addr.to_s

          batch << diff

          if version.id > store_id
            store_id = version.id
          end
        end

        if batch.any?
          logger.info "artist versions: inserting #{last_id}..#{store_id}"
          partition_timestamp = batch[0][:updated_at].strftime("%Y%m%d")
          result = gbq.insert("artist_versions_part$#{partition_timestamp}", batch)
          if result["insertErrors"]
            logger.error result.inspect
          else
            redis.set("artist-version-exporter-id-part", store_id)
          end
        end

      rescue Exception => e
        logger.error "error: #{e}"
      end
    end
  end
end
