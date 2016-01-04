#!/home/danbooru/.rbenv/shims/ruby

require "redis"
require "logger"
require "aws-sdk"
require 'optparse'
require File.expand_path("../../../config/environment", __FILE__)
require 'lru_redux'

# your environment should set AWS_REGION, AWS_ACCESS_KEY, and 
# AWS_SECRET_ACCESS_KEY

Process.daemon
# Process.setpriority(Process::PRIO_USER, 0, 10)

$running = true
$options = {
  pidfile: "/var/run/reportbooru/related_tag_worker.pid",
  logfile: "/var/log/reportbooru/related_tag_worker.log"
}

OptionParser.new do |opts|
  opts.on("--pidfile=PIDFILE") do |pidfile|
    $options[:pidfile] = pidfile
  end

  opts.on("--logfile=LOGFILE") do |logfile|
    $options[:logfile] = logfile
  end
end.parse!

LOGGER = Logger.new(File.open($options[:logfile], "a"))
REDIS = Redis.new
SQS_QUEUE_URL = Rails.application.config.x.aws_sqs_related_tag_queue_url
SQS_CLIENT = Aws::SQS::Client.new
SQS_POLLER = Aws::SQS::QueuePoller.new(SQS_QUEUE_URL, client: SQS_CLIENT)
CACHE = LruRedux::Cache.new(200)

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
    if msg.body =~ /^calculate (.+)/
      tag_name = $1
      next if CACHE[tag_name]
      LOGGER.info "processing #{tag_name}"
      begin
        calc = TagSimilarityCalculator.new(tag_name)
        calc.calculate
        calc.update_danbooru if calc.results
      rescue Exception => e
        LOGGER.error e.message
        LOGERR.error e.backtrace.join("\n")
      end
      CACHE[tag_name] = true
    end
  end
end
