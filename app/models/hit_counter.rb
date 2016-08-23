require "digest/md5"

class HitCounter
  include Concerns::RedisCounter
  class VerificationError < SecurityError ; end
  class UnknownKeyError < Exception ; end

  LIMIT = 100

  def post_search_rank_day(date, limit)
    key = "ps-day-#{date.strftime('%Y%m%d')}"
    client.zrevrange(key, 0, limit, with_scores: true)
  end

  def post_search_rank_month(date, limit)
    key = "ps-month-#{date.strftime('%Y%m')}"
    client.zrevrange(key, 0, limit, with_scores: true)
  end

  def post_search_by_user(user_id)
    week1 = 2.weeks.ago.to_i / (60 * 60 * 24 * 7)
    week2 = 1.week.ago.to_i / (60 * 60 * 24 * 7)
    week3 = Time.now.to_i / (60 * 60 * 24 * 7)
    client.zunionstore("psu-#{user_id}", ["psu-#{user_id}-#{week1}", "psu-#{user_id}-#{week2}", "psu-#{user_id}-#{week3}"])
    client.expire("psu-#{user_id}", 60 * 60)
    client.zrevrange("psu-#{user_id}", 0, 5)
  end

  def prune!
    yesterday = 1.day.ago.strftime("%Y%m%d")
    last_week = 1.week.ago.strftime("%Y%U")
    last_month = 1.month.ago.strftime("%Y%m")

    client.zremrangebyrank("ps-day-#{yesterday}", 0, -LIMIT)
    client.zremrangebyrank("ps-week-#{last_week}", 0, -LIMIT)
    client.zremrangebyrank("ps-month-#{last_month}", 0, -LIMIT)
  end

  def count!(key, value, sig, user_id)
    validate!(key, value, sig)

    case key
    when /^ps-(.+)/
      increment_post_search_count($1, value, user_id)

    else
      raise UnknownKeyError.new
    end
  end

  def increment_post_search_count(tags, session_id, user_id)
    tags = normalize_tags(tags)
    code = hash(tags)
    today = Time.now.strftime("%Y%m%d")
    week = Time.now.to_i / (60 * 60 * 24 * 7)

    if client.pfadd("ps-#{code}-#{today}", session_id)
      month = Time.now.strftime("%Y%m")

      client.pipelined do
        client.expire("ps-#{code}-#{today}", 2.days)
        client.zincrby("ps-day-#{today}", 1, tags)
        client.zincrby("ps-month-#{month}", 1, tags)

        if user_id
          client.zincrby("psu-#{user_id}-#{week}", 1, tags)
          client.expire("psu-#{user_id}-#{week}", 4.weeks)
        end
      end
    end
  end
end
