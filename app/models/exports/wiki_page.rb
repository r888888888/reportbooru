module Exports
  class WikiPage
    BATCH_SIZE = 5000
    SCHEMA = {
      version_id: {type: "INTEGER"},
      version: {type: "INTEGER"},
      wiki_page_id: {type: "INTEGER"},
      created_at: {type: "TIMESTAMP"},
      updated_at: {type: "TIMESTAMP"},
      updater_id: {type: "INTEGER"},
      updater_ip_addr: {type: "STRING"},
      title: {type: "STRING"},
      body: {type: "STRING"},
      is_locked: {type: "BOOLEAN"},
      is_deleted: {type: "BOOLEAN"},
      other_names: {type: "STRING"}
    }

    attr_reader :redis, :logger, :gbq

    def initialize(redis, logger, gbq)
      @redis = redis
      @logger = logger
      @gbq = gbq
    end

    def get_last_exported_id
      redis.get("wiki-exporter-id-part").to_i
    end

    def find_previous(version)
      DanbooruRo::WikiPageVersion.where("wiki_page_id = ? and updated_at < ?", version.wiki_page_id, version.updated_at).order("updated_at desc, id desc").first
    end

    def find_version_number(version)
      1 + DanbooruRo::WikiPageVersion.where("wiki_page_id = ? and updated_at < ?", version.wiki_page_id, version.updated_at).count
    end

    def create_table
      begin
        gbq.create_table("wiki_page_versions_part", SCHEMA, enable_partitioning: true)
      rescue Google::Apis::ClientError
      end
    end

    def calculate_diff(a, b)
      changes = {}

      if a.nil? || a.title != b.title
        changes[:title] = b.title
      end

      if a.nil? || a.body != b.body
        changes[:body] = b.body
      end

      if a.nil? || a.is_locked != b.is_locked
        changes[:is_locked] = b.is_locked
      end

      if a.nil? || a.is_deleted != b.is_deleted
        changes[:is_deleted] = b.is_deleted
      end

      if a.nil? || a.other_names != b.other_names
        changes[:other_names] = b.other_names.join("\n")
      end

      return changes
    end

    def execute
      create_table

      last_id = get_last_exported_id
      next_id = last_id + BATCH_SIZE
      store_id = last_id
      batch = []
      DanbooruRo::WikiPageVersion.where("id > ? and id <= ? and updated_at < ?", last_id, next_id, 70.minutes.ago).find_each do |version|
        previous = find_previous(version)
        diff = calculate_diff(previous, version)
        diff[:version_id] = version.id
        diff[:version] = find_version_number(version)
        diff[:created_at] = version.created_at
        diff[:updated_at] = version.updated_at
        diff[:wiki_page_id] = version.wiki_page_id
        diff[:updater_id] = version.updater_id
        diff[:updater_ip_addr] = version.updater_ip_addr.to_s
        batch << diff

        if version.id > store_id
          store_id = version.id
        end
      end

      if batch.any?
        logger.info "wiki: inserting #{last_id}..#{store_id}"
        partition_timestamp = batch[0][:updated_at].strftime("%Y%m%d")
        result = gbq.insert("wiki_page_versions_part$#{partition_timestamp}", batch)
        if result["insertErrors"]
          logger.error result.inspect
        else
          redis.set("wiki-exporter-id-part", store_id)
        end
      end
    end
  end
end
