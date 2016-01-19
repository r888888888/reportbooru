require "digest/md5"

class HitCounter
  class VerificationError < SecurityError ; end
  class UnknownKeyError < Exception ; end

  LIMIT = 100

  def post_search_rank_day(date, limit)
    key = "ps-day-#{date.strftime('%Y%m%d')}"
    client.zrevrange(key, 0, limit, with_scores: true)
  end

  def post_search_rank_week(date, limit)
    key = "ps-week-#{date.strftime('%Y%U')}"
    client.zrevrange(key, 0, limit, with_scores: true)
  end

  def post_search_rank_month(date, limit)
    key = "ps-month-#{date.strftime('%Y%m')}"
    client.zrevrange(key, 0, limit, with_scores: true)
  end

  def post_search_rank_year(date, limit)
    []
  end

  def prune!
    yesterday = 1.day.ago.strftime("%Y%m%d")
    last_week = 1.week.ago.strftime("%Y%U")
    last_month = 1.month.ago.strftime("%Y%m")

    client.zremrangebyrank("ps-day-#{yesterday}", 0, -LIMIT)
    client.zremrangebyrank("ps-week-#{last_week}", 0, -LIMIT)
    client.zremrangebyrank("ps-month-#{last_month}", 0, -LIMIT)
  end

  def count!(key, value, sig)
    validate!(key, value, sig)

    case key
    when /^ps-(.+)/
      increment_post_search_count($1, value)

    else
      raise UnknownKeyError.new
    end
  end

  def validate!(key, value, sig)
    digest = OpenSSL::Digest.new("sha256")
    calc_sig = OpenSSL::HMAC.hexdigest(digest, Rails.application.config.x.shared_remote_key, "#{key},#{value}")

    if calc_sig != sig
      raise VerificationError.new
    end
  end

  def increment_post_search_count(tags, session_id)
    tags = normalize_tags(tags)
    code = hash(tags)
    today = Time.now.strftime("%Y%m%d")

    if client.pfadd("ps-#{code}-#{today}", session_id)
      week = Time.now.strftime("%Y%U")
      month = Time.now.strftime("%Y%m")

      client.pipelined do
        client.expire("ps-#{code}-#{today}", 2.days)
        client.zincrby("ps-day-#{today}", 1, tags)
        client.zincrby("ps-week-#{week}", 1, tags)
        client.zincrby("ps-month-#{month}", 1, tags)
      end
    end
  end

  def client
    @client ||= Redis.new
  end

  def hash(string)
    Digest::MD5.hexdigest(string)
  end

  def normalize_tags(tags)
    tags.to_s.gsub(/\u3000/, " ").downcase.strip.scan(/\S+/).uniq.sort.join(" ")
  end
end
