class HitCounter
  def post_view_count(post_id)
    client.pfcount("pv-#{post_id}")
  end

  def post_view_rank_day(date, limit)
    key = "pv-day-#{date.strftime('%Y%m%d')}"
    Post.find(client.zrange(key, 0, limit))
  end

  def post_view_rank_week(date, limit)
    key = "pv-week-#{date.strftime('%Y%U')}"
    Post.find(client.zrange(key, 0, limit))
  end

  def post_view_rank_year(date, limit)
    key = "pv-year-#{date.strftime('%Y')}"
    Post.find(client.zrange(key, 0, limit))
  end

  def clean_day(date)
    client.zremrangebyrank("pv-day-#{date.strftime("%Y%m%d")}", 40, -1)
    client.zremrangebyrank("pv-week-#{date.strftime("%Y%U")}", 40, -1)
    client.zremrangebyrank("pv-year-#{date.strftime("%Y")}", 40, -1)
  end

  def count!(key, value, sig)
    validate!(key, value, sig)

    case key
    when /^show-(\d+)/
      increment_post_views($1, value)

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

  def increment_post_views(post_id, session_id)
    if client.pfadd("pv-#{post_id}", session_id)
      today = Time.now.strftime("%Y%m%d")
      client.zincrby("pv-day-#{today}", 1, post_id)

      week = Time.now.strftime("%Y%U")
      client.zincrby("pv-week-#{week}", 1, post_id)

      year = Time.now.strftime("%Y")
      client.zincrby("pv-year-#{year}", 1, post_id)
    end
  end

  def client
    @client ||= Redis.new
  end
end
