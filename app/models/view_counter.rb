# Similar to hit counter, but only uses Redis as a cache and persists
# the counts on DynamoDB.

# requirements:
# - all counts are for a unique session
# - every time a user visits a post in a day, count that as one view
# - get a count of unique visitors for a post for a day
#   - key: hll-$POSTID-$DATE (expires in 1 day)
# - get a count of unique visitors for a post for all time
#   - key: vc-$POSTID (expires in 1 day, backed by dynamodb)
# - get the most viewed posts on a given day
#   - key: vc-rank-$DATE (expires in 1 day, backed by dynamodb)

require 'memoist'

class ViewCounter
  extend Memoist

  def redis
    Redis.new
  end

  memoize :redis

  def get_count(post_id)
    key = "vc-#{post_id}"
    (redis.get(key) || fetch_post_view_count(post_id)).to_i
  end

  def count!(post_id, session_id)
    full_key = "vc-#{post_id}"
    if unique?(post_id, session_id)
      val = increment_redis_count(post_id)
      add_rank(post_id)
      redis.setex("udb-#{post_id}", 10, "1")
      val
    else
      redis.get(full_key).to_i
    end
  end

  def increment_redis_count(post_id)
    key = "vc-#{post_id}"
    if redis.exists(key)
      val = redis.incr(key)
      redis.expire(key, redis_expiry)
      update_dynamodb_count(post_id, val) if update_dynamodb?(post_id)
    else
      val = fetch_post_view_count(post_id)
    end
    return val
  end

  def assign_redis_count(post_id, count)
    key = "vc-#{post_id}"
    redis.setex(key, redis_expiry, count)
  end

  def fetch_post_view_count(post_id)
    key = {
      "post_id" => post_id
    }
    resp = dynamodb.get_item(key: key, table_name: "post_views_#{Rails.env}")
    if resp.item
      val = resp.item["count"].to_i
    else
      val = 0
    end
    val += 1
    assign_redis_count(post_id, val)
    val
  end

  def update_dynamodb_count(post_id, count)
    item = {
      "post_id" => post_id,
      "count" => count
    }
    dynamodb.put_item(table_name: "post_views_#{Rails.env}", item: item)
  end

  def date_key
    Time.now.strftime("%Y-%m-%d")
  end

  memoize :date_key

  def unique?(post_id, session_id)
    key = "hll-#{date_key}-#{post_id}"
    if redis.pfadd(key, session_id)
      redis.expire(key, redis_expiry)
      return true
    else
      return false
    end
  end

  def add_rank(post_id)
    key = "vc-rank-#{date_key}"
    redis.zincrby(key, 1, post_id)
    redis.expire(key, redis_expiry)
    update_dynamodb_rank(date_key, get_rank(date_key, 100).to_json) if redis.get("udb-rank").nil?
  end

  def get_rank(date, limit)
    key = "vc-rank-#{date}"
    if redis.exists(key)
      redis.zrevrange(key, 0, limit, with_scores: true)
    else
      fetch_rank(date)
    end
  end

  def assign_redis_rank(date, jsons)
    redis.setex("vc-rank-#{date}", redis_expiry, jsons)
  end

  def update_dynamodb_rank(date, jsons)
    item = {
      "date" => date,
      "data" => jsons
    }
    dynamodb.put_item(table_name: "post_view_summaries_#{Rails.env}", item: item)
    redis.setex("udb-rank", 60, "1")
  end

  def fetch_rank(date)
    key = {
      "date" => date
    }
    resp = dynamodb.get_item(key: key, table_name: "post_view_summaries_#{Rails.env}")
    if resp.item
      assign_redis_rank(date, resp.item["data"])
      return JSON.parse(resp.item["data"])
    else
      return nil
    end
  end

  def redis_expiry
    1.day
  end

  def dynamodb
    Aws::DynamoDB::Client.new(region: "us-west-1")
  end

  memoize :dynamodb

  def update_dynamodb?(post_id)
    redis.get("udb-#{post_id}").nil?
  end
end
