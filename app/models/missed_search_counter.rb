require "digest/md5"

class MissedSearchCounter
  include Concerns::RedisCounter
  class UnknownKeyError < Exception ; end

  LIMIT = 100

  def rank
    date = Date.today
    keys = 7.times.map {|x| "msc-#{date.prev_day(x).strftime('%Y%m%d')}"}
    client.zunionstore("msc-all", keys)
    client.zrevrange("msc-all", 0, LIMIT, with_scores: true)
  end

  def count!(tags, session_id)
    tags = normalize_tags(tags)
    code = hash(tags)
    today = Time.now.strftime("%Y%m%d")

    if client.pfadd("msc-#{code}-#{today}", session_id)
      client.pipelined do
        client.expire("msc-#{code}-#{today}", 1.day)
        client.zincrby("msc-#{today}", 1, tags)
        client.expire("msc-#{today}", 7.days)
      end
    end
  end
end
