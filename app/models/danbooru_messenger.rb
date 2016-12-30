# Sends dmails to users on Danbooru

class DanbooruMessenger
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
