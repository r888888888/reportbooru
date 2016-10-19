module Concerns
  module RedisCounter
    class VerificationError < SecurityError ; end

    def client
      @client ||= Redis.new
    end

    def hash(string)
      Digest::MD5.hexdigest(string)
    end

    def normalize_tags(tags)
      tags.to_s.gsub(/\u3000/, " ").downcase.strip.scan(/\S+/).uniq.sort.join(" ")
    end

    def validate!(key, value, sig)
      digest = OpenSSL::Digest.new("sha256")
      calc_sig = OpenSSL::HMAC.hexdigest(digest, ENV["DANBOORU_SHARED_REMOTE_KEY"], "#{key},#{value}")

      if calc_sig != sig
        raise VerificationError.new
      end
    end
  end
end
