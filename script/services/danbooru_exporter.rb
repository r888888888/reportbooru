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

while $running
  begin
    [Exports::Note, Exports::FlatPostVersion, Exports::PostVersion, Exports::WikiPage, Exports::ArtistVersion, Exports::PostVote].each do |exporter|
      exporter.new(REDIS, LOGGER, GBQ).execute
      exit unless $running
    end
  rescue Exception => e
    LOGGER.error("error: #{e}")
  end

  10.times do
    sleep(1)
    exit unless $running
  end
end
