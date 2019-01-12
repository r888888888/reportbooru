#!/usr/bin/env ruby

=begin
[Unit]
Description=Reportbooru Exporter

[Service]
Type=simple
User=danbooru
Restart=always
WorkingDirectory=/var/www/reportbooru/current
ExecStart=/bin/bash -lc 'bundle exec ruby script/services/danbooru_exporter.rb'
TimeoutSec=30
RestartSec=15s

[Install]
WantedBy=multi-user.target
=end

require "dotenv"
Dotenv.load

require "redis"
require "logger"
require 'optparse'
require "json"
require "big_query"
require "aws-sdk"
require File.expand_path("../../../config/environment", __FILE__)

$running = true
$options = {
  logfile: "/var/log/reportbooru/danbooru_exporter.log",
  google_key_path: ENV["google_api_key_path"],
  google_data_set: "danbooru_#{Rails.env}"
}

OptionParser.new do |opts|
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

Signal.trap("TERM") do
  $running = false
end

while $running
  begin
    [Exports::Note, Exports::FlatPostVersion, Exports::PostVersion, Exports::WikiPage, Exports::ArtistVersion, Exports::PostVote, Exports::Favorites].each do |exporter|
      exporter.new(REDIS, LOGGER, GBQ).execute
      exit unless $running
    end
  rescue PG::ConnectionBad, PG::UnableToSend => e
    LOGGER.error "error: #{e}"
    DanbooruRo::ArtistVersion.connection.reconnect!
    DanbooruRo::Favorite.connection.reconnect!
    DanbooruRo::NoteVersion.connection.reconnect!
    DanbooruRo::PostVote.connection.reconnect!
    DanbooruRo::WikiPageVersion.connection.reconnect!
    Archive::PostVersion.connection.reconnect!
    Archive::PoolVersion.connection.reconnect!
  rescue Exception => e
    LOGGER.error("error: #{e}")
    LOGGER.error e.backtrace.join("\n")
  end

  10.times do
    sleep(1)
    exit unless $running
  end
end
