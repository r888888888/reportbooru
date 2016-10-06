#!/home/danbooru/.rbenv/shims/ruby

require "redis"
require "logger"
require 'optparse'
require "json"
require "big_query"
require File.expand_path("../../../config/environment", __FILE__)

Process.daemon
Process.setpriority(Process::PRIO_USER, 0, 10)

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

$running = true
$options = {
  pidfile: "/var/run/reportbooru/flat_note_version_exporter.pid",
  logfile: "/var/log/reportbooru/flat_note_version_exporter.log",
  google_key_path: "/var/www/reportbooru/shared/google-key.json",
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

google_config = JSON.parse(File.read($options[:google_key_path]))

logfile = File.open($options[:logfile], "a")
logfile.sync = true
LOGGER = Logger.new(logfile)
REDIS = Redis.new
BATCH_SIZE = 1000
GBQ = BigQuery::Client.new(
  "json_key" => $options[:google_key_path],
  "project_id" => google_config["project_id"],
  "dataset" => $options[:google_data_set]
)

File.open($options[:pidfile], "w") do |f|
  f.write(Process.pid)
end

Signal.trap("TERM") do
  $running = false
end

def get_last_exported_id
  REDIS.get("flat-note-version-exporter-id").to_i
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

begin
  GBQ.create_table("note_versions_flat", SCHEMA)
rescue Google::Apis::ClientError
end

while $running
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
      LOGGER.info "inserting #{last_id}..#{store_id}"
      result = GBQ.insert("note_versions_flat", batch)
      if result["insertErrors"]
        LOGGER.error result.inspect
        sleep(180)
      else
        REDIS.set("flat-note-version-exporter-id", store_id)
      end
    else
      sleep(60)
    end

  rescue Exception => e
    LOGGER.error "error: #{e}"
    sleep(60)
    retry
  end
end
