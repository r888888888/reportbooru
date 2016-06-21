#!/home/danbooru/.rbenv/shims/ruby

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
  pidfile: "/var/run/reportbooru/async_report_worker.pid",
  logfile: "/var/log/reportbooru/async_report_worker.log",
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
BATCH_SIZE = 10_000
GBQ = BigQuery::Client.new(
  "json_key" => $options[:google_key_path],
  "project_id" => google_config["project_id"],
  "dataset" => $options[:google_data_set]
)
SQS_QUEUE_URL = Rails.application.config.x.aws_sqs_report_queue_url
SQS_CLIENT = Aws::SQS::Client.new
SQS_POLLER = Aws::SQS::QueuePoller.new(SQS_QUEUE_URL, client: SQS_CLIENT)

def report_post_versions_removed(json)
  tag = json["tag"]
  email = json["email"]
  report = ""
  report << "<h1>Post Changes - Removing #{tag}</h1>"
  report <<"<ul>\n"
  results = BigQuery::PostVersion.new.find_removed(tag)
  if results["rows"].blank?
    report << "<li>No matches found</li>\n"
  else
    results["rows"].each do |row|
      version_id = row["f"][0]["v"]
      post_id = row["f"][1]["v"]
      updated_at = Time.at(row["f"][2]["v"].to_f)
      updater_id = row["f"][3]["v"]
      updater_ip_addr = row["f"][4]["v"]
      tags = row["f"][5]["v"]
      added_tags = row["f"][6]["v"]
      removed_tags = row["f"][7]["v"]
      parent_id = row["f"][8]["v"]
      rating = row["f"][9]["v"]
      source = row["f"][10]["v"]

      report << %{<li><a href="#{Rails.application.config.x.danbooru_hostname}/post_versions?search[post_id]=#{post_id}&hilite=#{version_id}">post ##{post_id}</a> | removed: #{removed_tags}</li>\n}
    end

  end

  report << "</ul>\n"
  LOGGER.info "Emailed report for removing #{tag} to #{email}"
  send_email(email, "Danbooru Post Change Report", report)
end

def report_post_versions_added(json)
  tag = json["tag"]
  email = json["email"]
  report = ""
  report << "<h1>Post Changes - Adding #{tag}</h1>"
  report << "<ul>\n"
  results = BigQuery::PostVersion.new.find_removed(tag)
  if results["rows"].blank?
    report << "<li>No matches found</li>\n"
  else
    results["rows"].each do |row|
      version_id = row["f"][0]["v"]
      post_id = row["f"][1]["v"]
      updated_at = Time.at(row["f"][2]["v"].to_f)
      updater_id = row["f"][3]["v"]
      updater_ip_addr = row["f"][4]["v"]
      tags = row["f"][5]["v"]
      added_tags = row["f"][6]["v"]
      removed_tags = row["f"][7]["v"]
      parent_id = row["f"][8]["v"]
      rating = row["f"][9]["v"]
      source = row["f"][10]["v"]

      report << %{<li><a href="#{Rails.application.config.x.danbooru_hostname}/post_versions?search[post_id]=#{post_id}&hilite=#{version_id}">post ##{post_id}</a> | added: #{added_tags}</li>\n}
    end
  end

  report << "</ul>\n"
  LOGGER.info "Emailed report for adding #{tag} to #{email}"
  send_email(email, "Danbooru Post Change Report", report)
end

def send_email(destination, subject, body)
  Pony.mail(
    to: destination,
    from: Rails.application.config.x.admin_email,
    subject: subject,
    body: body,
    content_type: "text/html"
  )
end

File.open($options[:pidfile], "w") do |f|
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
  begin
    SQS_POLLER.poll do |msg|
      json = JSON.parse(msg.body)

      if json["type"] == "post_versions_removed"
        report_post_versions_removed(json)
      elsif json["type"] == "post_versions_added"
        report_post_versions_added(json)
      end
    end
  rescue Exception => e
    LOGGER.error "error: #{e}"
    sleep(60)
    retry
  end
end
