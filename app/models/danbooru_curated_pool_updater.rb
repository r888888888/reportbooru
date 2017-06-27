class DanbooruCuratedPoolUpdater
  def update_pool
    pool_id = ENV["DANBOORU_CURATED_POOL_ID"].to_i

    attribs = {
      "login" => ENV["DANBOORU_REPORTBOT_LOGIN"],
      "api_key" => ENV["DANBOORU_REPORTBOT_API_KEY"],
      "pool[post_ids]" => find_posts.join(" ")
    }

    uri = URI.parse("#{ENV['DANBOORU_REPORTBOT_HOST']}/pools/#{pool_id}.json")

    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.is_a?(URI::HTTPS)) do |http|
      req = Net::HTTP::Patch.new(uri.request_uri)
      req.set_form_data(attribs)
      resp = http.request(req)
      if resp.is_a?(Net::HTTPSuccess)
        return true
      else
        raise "HTTP error code: #{resp.code} #{resp.message}"
      end
    end
  end

  def find_posts
    max_id = DanbooruRo::Post.maximum(:id) - 8000
    super_voters = DanbooruRo::SuperVoter.pluck(:user_id)
    desired_count = 500
    posts = nil
    (1..20).detect do |x|
      posts = DanbooruRo::PostVote.where(user_id: super_voters).where("post_id > ?", max_id).group("post_id").having("count(*) >= ?", x).pluck("post_id")
      posts.size < desired_count
    end
    return posts
  end
end
