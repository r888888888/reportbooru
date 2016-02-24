require 'aws-sdk'

class UserSimilarityQuery
  MIN_FAV_COUNT = 200

  attr_reader :user_id

  def initialize(user_id)
    @user_id = user_id
  end

  def results
    if redis.zcard(redis_key) == 0
      sqs_client.send_message(
        message_body: redis_key,
        queue_url: Rails.application.config.x.aws_sqs_similarity_queue_url
      )
      return "not ready"
    else
      redis.zrevrange(redis_key, 0, 12, with_scores: true)
    end
  end

  def results_text
    ret = results()
    if ret == "not ready"
      return ret
    else
      return ret.join(" ")
    end
  end

  def calculate
    return if redis.zcard(redis_key) > 0

    posts0 = Favorite.for_user(user_id).pluck_rows(:post_id)
    User.where("id <> ? and favorite_count > ? and last_logged_in_at >= ?", user_id, MIN_FAV_COUNT, 1.year.ago).pluck_rows(:id).each do |user_id|
      posts1 = Favorite.for_user(user_id).pluck_rows(:post_id)
      redis.zadd(redis_key, calculate_with_weighted_cosine(posts0, posts1), user_id)
    end
    redis.zremrangebyrank(redis_key, 0, -13)
    redis.expire(redis_key, 36.hours.to_i)
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
    # when these are < 1 million in size this ends up
    # being faster than trying to farm out to map reduce
    a = (posts0 & posts1).size
    div = Math.sqrt(posts0.size * posts1.size)
    if div == 0
      0
    else
      a / div
    end
  end

  def calculate_with_weighted_cosine(posts0, posts1)
    n = Post.maximum(:id).to_f
    a = (posts0 & posts1).map {|x| x.to_f / n}.sum
    div = Math.sqrt(posts0.size * posts1.size)
    if div == 0
      0
    else
      a / div
    end
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
