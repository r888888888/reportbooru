require "digest/md5"

class SearchCounter
  include Concerns::RedisCounter
  class UnknownKeyError < Exception ; end

  LIMIT = 100

  def self.expunge!
    redis = Redis.new
    redis.scan_each(match: "ps-week-*") do |key|
      redis.del(key)
    end
    redis.scan_each(match: "ps-month-*") do |key|
      redis.del(key)
    end
    redis.scan_each(match: "psu-*") do |key|
      redis.del(key)
    end
  end

  def get_rank(date, limit)
    key = "ps-day-#{date.strftime('%Y%m%d')}"
    client.zrevrange(key, 0, limit, with_scores: true)
  end

  def prune!
    yesterday = 1.day.ago.strftime("%Y%m%d")

    client.zremrangebyrank("ps-day-#{yesterday}", 0, -LIMIT)
  end

  def count!(key, value)
    case key
    when /^ps-(.+)/
      increment_post_search_count($1, value)

    else
      raise UnknownKeyError.new
    end
  end

  def increment_post_search_count(tags, session_id)
    tags = normalize_tags(tags)
    code = hash(tags)
    today = Time.now.strftime("%Y%m%d")
    week = Time.now.to_i / (60 * 60 * 24 * 7)

    if client.pfadd("ps-#{code}-#{today}", session_id)
      month = Time.now.strftime("%Y%m")

      client.pipelined do
        client.expire("ps-#{code}-#{today}", 2.days)
        client.zincrby("ps-day-#{today}", 1, tags)
      end
    end
  end
end
