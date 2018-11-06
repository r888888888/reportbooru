#!/usr/bin/env ruby

=begin
[Unit]
Description=Reportbooru Misc Worker

[Service]
Type=simple
User=danbooru
Restart=always
WorkingDirectory=/var/www/reportbooru/current
ExecStart=/bin/bash -lc 'bundle exec ruby script/services/misc_worker.rb'
TimeoutSec=30
RestartSec=15s

[Install]
WantedBy=multi-user.target
=end

require "dotenv"
Dotenv.load

require "redis"
require "logger"
require "aws-sdk"
require 'optparse'
require File.expand_path("../../../config/environment", __FILE__)

# your environment should set AWS_REGION, AWS_ACCESS_KEY, and 
# AWS_SECRET_ACCESS_KEY

$running = true
$options = {
  logfile: "/var/log/reportbooru/misc_worker.log"
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
SQS_QUEUE_URL = ENV["aws_sqs_misc_url"]
SQS_CLIENT = Aws::SQS::Client.new
SQS_POLLER = Aws::SQS::QueuePoller.new(SQS_QUEUE_URL, client: SQS_CLIENT)

Signal.trap("TERM") do
  $running = false
end

SQS_POLLER.before_request do
  unless $running
    throw :stop_polling
  end
end

while $running
  begin
    SQS_POLLER.poll do |msg|
      if msg.body =~ /targetedpostdownvoting-(\d+)-(\d+)/
        user_id = $1
        post_id = $2
        LOGGER.info "processing targeted post down voting report for #{user_id}"
        MessagedReports::TargetedPostDownVoting.new(user_id, post_id).send_message
      else
        LOGGER.error "unknown message: #{msg.body}"
      end
    end
  rescue PG::ConnectionBad, PG::UnableToSend => e
    LOGGER.error "error: #{e}"
    DanbooruRo::Base.connection.reconnect!
  rescue Exception => e
    LOGGER.error e.message
    LOGGER.error e.backtrace.join("\n")
    30.times do
      sleep(1)
      exit unless $running
    end
    retry
  end
end
