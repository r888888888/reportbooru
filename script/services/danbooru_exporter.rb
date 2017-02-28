#!/usr/bin/env ruby

require "dotenv"
Dotenv.load

require "redis"
require "logger"
require 'optparse'
require "json"
require "big_query"
require "aws-sdk"
require File.expand_path("../../../config/environment", __FILE__)

Process.daemon
Process.setpriority(Process::PRIO_USER, 0, 10)

$running = true
$options = {
  pidfile: "/var/run/reportbooru/danbooru_exporter.pid",
  logfile: "/var/log/reportbooru/danbooru_exporter.log",
  google_key_path: ENV["google_api_key_path"],
  google_data_set: "danbooru_#{Rails.env}"
}

OptionParser.new do |opts|
  opts.on("--pidfile=PIDFILE") do |pidfile|
    $options[:pidfile] = pidfile
  end

  opts.on("--logfile=LOGFILE") do |logfile|
    $options[:logfile] = logfile
  end

  opts.on("--google_key=KEYFILE") do |keyfile|
    $options[:google_key_path] = keyfile
  end
end.parse!

$google_config = JSON.parse(File.read($options[:google_key_path]))

logfile = File.open($options[:logfile], "a")
logfile.sync = true
LOGGER = Logger.new(logfile)
REDIS = Redis.new
GBQ = BigQuery::Client.new(
  "json_key" => $options[:google_key_path],
  "project_id" => $google_config["project_id"],
  "dataset" => $options[:google_data_set]
)

File.open($options[:pidfile], "w") do |f|
  f.write(Process.pid)
end

Signal.trap("TERM") do
  $running = false
end

class ArtistVersionExporter
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

class NoteExporter
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

    rescue Exception => e
      logger.error "error: #{e}"
    end
  end
end

class FlatPostVersionExporter
  BATCH_SIZE = 1000
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

    rescue Exception => e
      logger.error "error: #{e}"
    end
  end
end

class PostVersionExporter
  BATCH_SIZE = 1000

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
    begin
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

    rescue Exception => e
      logger.error "error: #{e}"
    end
  end
end

class WikiPageExporter
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

    # if a.nil? || a.is_deleted != b.is_deleted
    #   changes[:is_deleted] = b.is_deleted
    # end

    if a.nil? || a.other_names != b.other_names
      changes[:other_names] = b.other_names
    end

    return changes
  end

  def execute
    begin
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

    rescue Exception => e
      logger.error "error: #{e}"
    end
  end
end

while $running
  begin
    NoteExporter.new(REDIS, LOGGER, GBQ).execute
    exit unless $running
    FlatPostVersionExporter.new(REDIS, LOGGER, GBQ).execute
    exit unless $running
    PostVersionExporter.new(REDIS, LOGGER, GBQ).execute
    exit unless $running
    WikiPageExporter.new(REDIS, LOGGER, GBQ).execute
    exit unless $running
    ArtistVersionExporter.new(REDIS, LOGGER, GBQ).execute
    exit unless $running
  rescue Exception => e
    LOGGER.error("error: #{e}")
  end

  10.times do
    sleep(1)
    exit unless $running
  end
end
