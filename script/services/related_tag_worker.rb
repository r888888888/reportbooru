#!/usr/bin/env ruby

=begin
[Unit]
Description=Reportbooru Related Tag Worker

[Service]
Type=simple
User=danbooru
Restart=always
WorkingDirectory=/var/www/reportbooru/current
ExecStart=/bin/bash -lc 'bundle exec ruby script/services/related_tag_worker.rb'
TimeoutSec=30
RestartSec=15s

[Install]
WantedBy=multi-user.target
=end

require "redis"
require "logger"
require "aws-sdk"
require 'optparse'
require File.expand_path("../../../config/environment", __FILE__)
require 'lru_redux'

# your environment should set AWS_REGION, AWS_ACCESS_KEY, and 
# AWS_SECRET_ACCESS_KEY

$running = true
$options = {
  logfile: "/var/log/reportbooru/related_tag_worker.log"
}

OptionParser.new do |opts|
  opts.on("--logfile=LOGFILE") do |logfile|
    $options[:logfile] = logfile
  end
end.parse!

logfile = File.open($options[:logfile], "a")
logfile.sync = true
LOGGER = Logger.new(logfile)
REDIS = Redis.new
SQS_QUEUE_URL = ENV["aws_sqs_related_tag_queue_url"]
SQS_CLIENT = Aws::SQS::Client.new
SQS_POLLER = Aws::SQS::QueuePoller.new(SQS_QUEUE_URL, client: SQS_CLIENT)
CACHE = LruRedux::TTL::Cache.new(200, 5 * 60)

Signal.trap("TERM") do
  $running = false
end

SQS_POLLER.before_request do
  unless $running
    throw :stop_polling
  end
end

def process_calculate(tag_name)
  LOGGER.info "processing #{tag_name}"

  if CACHE[tag_name]
    LOGGER.info "  skipped"
    return
  end

  calc = TagSimilarityCalculator.new(tag_name)
  calc.calculate

  if calc.results
    calc.update_danbooru 
  else
    LOGGER.info "  skipped"
  end

  CACHE[tag_name] = true
end

while $running
  begin
    SQS_POLLER.poll do |msg|
      if msg.body =~ /^calculate (.+)/
        process_calculate($1)
      else
        LOGGER.error "unknown message: #{msg.body}"
      end
    end
  rescue Exception => e
    LOGGER.error "error: #{e}"
    LOGGER.error e.backtrace.join("\n")

    DanbooruRo::ArtistVersion.connection.reconnect!
    DanbooruRo::Favorite.connection.reconnect!
    DanbooruRo::NoteVersion.connection.reconnect!
    DanbooruRo::PostVote.connection.reconnect!
    DanbooruRo::WikiPageVersion.connection.reconnect!
    DanbooruRo::Tag.connection.reconnect!
    Archive::PostVersion.connection.reconnect!
    Archive::PoolVersion.connection.reconnect!
    
    30.times do
      sleep(1)
      exit unless $running
    end
    retry
  end
end
