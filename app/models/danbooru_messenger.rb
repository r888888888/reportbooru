class DanbooruMessenger
  def write_forum_topic(category, title, body)
    attribs = {
      "login" => ENV["DANBOORU_REPORTBOT_LOGIN"],
      "api_key" => ENV["DANBOORU_REPORTBOT_API_KEY"],
      "forum_topic[title]" => title,
      "forum_topic[category_id]" => category_id,
      "forum_topic[original_post_attributes][body]" => body,
    }

    uri = URI.parse("#{ENV['DANBOORU_REPORTBOT_HOST']}/forum_topics.json")

    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.is_a?(URI::HTTPS)) do |http|
      req = Net::HTTP::Post.new(uri.request_uri)
      req.set_form_data(attribs)
      resp = http.request(req)
      if resp.is_a?(Net::HTTPSuccess)
        return true
      else
        raise "HTTP error code: #{resp.code} #{resp.message}"
      end
    end
  end

  def write_forum_post(topic_id, body)
    attribs = {
      "login" => ENV["DANBOORU_REPORTBOT_LOGIN"],
      "api_key" => ENV["DANBOORU_REPORTBOT_API_KEY"],
      "forum_post[topic_id]" => topic_id,
      "forum_post[body]" => body
    }

    uri = URI.parse("#{ENV['DANBOORU_REPORTBOT_HOST']}/forum_posts.json")

    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.is_a?(URI::HTTPS)) do |http|
      req = Net::HTTP::Post.new(uri.request_uri)
      req.set_form_data(attribs)
      resp = http.request(req)
      if resp.is_a?(Net::HTTPSuccess)
        return true
      else
        raise "HTTP error code: #{resp.code} #{resp.message}"
      end
    end
  end

  def send_message(user_id, title, body)
    attribs = {
      "login" => ENV["DANBOORU_REPORTBOT_LOGIN"],
      "api_key" => ENV["DANBOORU_REPORTBOT_API_KEY"],
      "dmail[to_id]" => user_id,
      "dmail[title]" => title,
      "dmail[body]" => body
    }

    uri = URI.parse("#{ENV['DANBOORU_REPORTBOT_HOST']}/dmails.json")

    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.is_a?(URI::HTTPS)) do |http|
      req = Net::HTTP::Post.new(uri.request_uri)
      req.set_form_data(attribs)
      resp = http.request(req)
      if resp.is_a?(Net::HTTPSuccess)
        return true
      else
        raise "HTTP error code: #{resp.code} #{resp.message}"
      end
    end
  end
end
