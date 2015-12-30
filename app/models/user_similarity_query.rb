class UserSimilarityQuery
  MIN_FAV_COUNT = 500

  attr_reader :user_id

  def initialize(user_id)
    @user_id = user_id
  end

  def results
    if redis.zcard(redis_key) == 0
      sqs_client.send_message(message_body: redis_key)
      return "not ready"
    else
      redis.zrevrange(redis_key, 0, 10)
    end
  end

  def calculate
    return if redis.zcard(redis_key) > 0

    posts0 = Favorite.for_user(user_id).pluck_rows(:post_id)
    User.where("fav_count > ?", MIN_FAV_COUNT).pluck_rows(:id).each do |row|
      posts1 = Favorite.for_user(row["id"]).pluck_rows(:post_id)
      redis.zadd(redis_key, calculate_with_cosine(posts0, posts1), row["id"])
    end
    redis.zremrangebyrank(redis_key, 0, -11)
    redis.expire(redis_key, 1.week.to_i)
  end

private

  def sqs_client
    @sqs_client ||= begin
      Aws::SQS::Client.new
    end
  end
  
  def redis_key
    "simusers-#{user_id}"
  end

  def redis
    @redis ||= Redis.new
  end

  def calculate_with_cosine(posts0, posts1)
    a = (posts0 & posts1).size
    a / Math.sqrt(posts0.size * posts1.size)
  end

  def calculate_with_mr_cosine(posts0, posts1)
    mapper = lambda {|x, y| x == y ? 1 : 0}
    reducer = lambda {|x| x.sum}

    results = posts0.map do |p0|
      posts1.map do |p1|
        mapper.call(p0, p1)
      end
    end
    a = reducer.call(results.flatten)
    a / Math.sqrt(posts0.size * posts1.size)
  end

  def calculate_with_mr_disco(posts0, posts1)
    # see https://blog.twitter.com/2012/dimension-independent-similarity-computation-disco
    gamma = 500.0
    prob = lambda {|x, y| rand < (gamma / Math.sqrt(x * y))}
    mapper = lambda {|x, y| x == y && prob.call(posts0.size, posts1.size) ? 1 : 0}
    reducer = lambda {|x| x.sum}

    results = posts0.map do |p0|
      posts1.map do |p1|
        mapper.call(p0, p1)
      end
    end
    a = reducer.call(results.flatten)
    a / gamma
  end

  def calculate_with_mr_dimsum(posts0, posts1)
    # see https://blog.twitter.com/2014/all-pairs-similarity-via-dimsum
    gamma = 500.0
    dot = Math.sqrt(posts0.size * posts1.size)
    prob = lambda {|x, y| rand < [1, gamma / dot].min}
    mapper = lambda do |x, y|
      x.map do |p0|
        y.map do |p1|
          prob.call(x.size, y.size) && p0 == p1 ? 1 : 0
        end
      end
    end
    reducer = lambda do |x|
      if gamma / dot > 1
        x.sum / dot
      else
        x.sum / gamma
      end
    end

    results = mapper.call(posts0, posts1).flatten
    reducer.call(results)
  end
end
