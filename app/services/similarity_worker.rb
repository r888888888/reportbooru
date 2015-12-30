#!/home/danbooru/.rbenv/shims/ruby

require "redis"
require "logger"
require "aws-sdk"
require 'optparse'
require File.expand_path("../../../config/environment", __FILE__)

# your environment should set AWS_REGION, AWS_ACCESS_KEY, and 
# AWS_SECRET_ACCESS_KEY

Process.daemon

$running = true
$options = {
  pidfile: "/var/run/reportbooru/similarity_worker.pid",
  logfile: "/var/log/reportbooru/similarity_worker.log"
}

OptionParser.new do |opts|
  opts.on("--pidfile") do |pidfile|
    $options[:pidfile] = pidfile
  end

  opts.on("--logfile") do |logfile|
    $options[:logfile] = logfile
  end
end.parse!

LOGGER = Logger.new(File.open($options[:logfile], "a"))
REDIS = Redis.new
SQS_QUEUE_URL = Rails.application.config.x.aws_sqs_similarity_queue_url
SQS_CLIENT = Aws::SQS::Client.new
SQS_POLLER = Aws::SQS::QueuePoller.new(SQS_QUEUE_URL, client: SQS_CLIENT)

File.open($options[:pidfile], "a") do |f|
  f.write(Process.pid)
end

Signal.trap("TERM") do
  $running = false
end

SQS_POLLER.before_request do
  unless $running
    throw :stop_polling
  end
end

while $running
  LOGGER.info "starting poll"

  SQS_POLLER.poll do |msg|
    if msg.body =~ /simusers-(\d+)/
      user_id = $1
      LOGGER.info "processing #{user_id}"
      query = UserSimilarityQuery.new(user_id)
      query.calculate
    end
  end
end
