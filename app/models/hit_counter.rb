class HitCounter
  class VerificationError < SecurityError ; end
  class UnknownKeyError < Exception ; end

  LIMIT = 100

  def post_search_count(tags)
    client.pfcount("ps-#{normalize_tags(tags)}")
  end

  def post_search_rank_day(date, limit)
    key = "ps-day-#{date.strftime('%Y%m%d')}"
    client.zrevrange(key, 0, limit, with_scores: true)
  end

  def post_search_rank_week(date, limit)
    key = "ps-week-#{date.strftime('%Y%U')}"
    client.zrevrange(key, 0, limit, with_scores: true)
  end

  def post_search_rank_year(date, limit)
    key = "ps-year-#{date.strftime('%Y')}"
    client.zrevrange(key, 0, limit, with_scores: true)
  end

  def prune!
    yesterday = 1.day.ago
    last_week = 1.week.ago
    last_year = 1.year.ago

    client.zremrangebyrank("ps-day-#{yesterday.strftime("%Y%m%d")}", 0, -LIMIT)
    client.zremrangebyrank("ps-week-#{last_week.strftime("%Y%U")}", 0, -LIMIT)
    client.zremrangebyrank("ps-year-#{last_year.strftime("%Y")}", 0, -LIMIT)
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
    if client.pfadd("ps-#{tags}", session_id)
      today = Time.now.strftime("%Y%m%d")
      client.zincrby("ps-day-#{today}", 1, tags)

      week = Time.now.strftime("%Y%U")
      client.zincrby("ps-week-#{week}", 1, tags)

      year = Time.now.strftime("%Y")
      client.zincrby("ps-year-#{year}", 1, tags)
    end
  end

  def client
    @client ||= Redis.new
  end

  def normalize_tags(tags)
    tags.to_s.gsub(/\u3000/, " ").strip.scan(/\S+/).uniq.sort.join(" ")
  end
end
