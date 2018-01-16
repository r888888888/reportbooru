module Exports
  class Note
    BATCH_SIZE = 1000
    SCHEMA = {
      version_id: {type: "INTEGER"},
      version: {type: "INTEGER"},
      created_at: {type: "TIMESTAMP"},
      updated_at: {type: "TIMESTAMP"},
      post_id: {type: "INTEGER"},
      note_id: {type: "INTEGER"},
      updater_id: {type: "INTEGER"},
      updater_ip_addr: {type: "STRING"},
      x: {type: "INTEGER"},
      y: {type: "INTEGER"},
      width: {type: "INTEGER"},
      height: {type: "INTEGER"},
      is_active: {type: "BOOLEAN"},
      body: {type: "STRING"}
    }

    attr_reader :redis, :logger, :gbq

    def initialize(redis, logger, gbq)
      @redis = redis
      @logger = logger
      @gbq = gbq
    end

    def get_last_exported_id
      redis.get("flat-note-version-exporter-id-part").to_i
    end

    def find_previous(version)
      DanbooruRo::NoteVersion.where("post_id = ? and updated_at < ?", version.post_id, version.updated_at).order("updated_at desc, id desc").first
    end

    def calculate_diff(a, b)
      changes = {}

      if a.nil? || a.body != b.body
        changes[:body] = b.body
      end

      if a.nil? || a.x != b.x
        changes[:x] = b.x
      end

      if a.nil? || a.y != b.y
        changes[:y] = b.y
      end

      if a.nil? || a.width != b.width
        changes[:width] = b.width
      end

      if a.nil? || a.height != b.height
        changes[:height] = b.height
      end

      if a.nil? || a.is_active != b.is_active
        changes[:is_active] = b.is_active
      end

      return changes
    end

    def create_table
      begin
        gbq.create_table("note_versions_flat_part", SCHEMA, enable_partitioning: true)
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
        DanbooruRo::NoteVersion.where("id > ? and id <= ? and updated_at < ?", last_id, next_id, 70.minutes.ago).find_each do |version|
          previous = find_previous(version)
          diff = calculate_diff(previous, version)
          diff[:version_id] = version.id
          diff[:version] = version.version
          diff[:created_at] = version.created_at
          diff[:updated_at] = version.updated_at
          diff[:post_id] = version.post_id
          diff[:note_id] = version.note_id
          diff[:updater_id] = version.updater_id
          diff[:updater_ip_addr] = version.updater_ip_addr.to_s

          batch << diff

          if version.id > store_id
            store_id = version.id
          end
        end

        if batch.any?
          logger.info "note versions: inserting #{last_id}..#{store_id}"
          partition_timestamp = batch[0][:updated_at].strftime("%Y%m%d")
          result = gbq.insert("note_versions_flat_part$#{partition_timestamp}", batch)
          if result["insertErrors"]
            logger.error result.inspect
          else
            redis.set("flat-note-version-exporter-id-part", store_id)
          end
        end

      rescue PG::ConnectionBad => e
        logger.error "error: #{e}"
        DanbooruRo::Base.connection.reconnect!
      rescue Exception => e
        logger.error "error: #{e}"
      end
    end
  end
end
