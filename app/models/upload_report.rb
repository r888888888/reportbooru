class UploadReport
  class ReportError < RangeError ; end
  class VerificationError < SecurityError ; end

  attr_reader :min_date, :max_date, :queries

  def initialize(min_date, max_date, queries, sig)
    @min_date = min_date.to_date
    @max_date = max_date.to_date
    @queries = queries.split(/,/)

    validate(sig)
  end

  def chart_data
    hash = date_hash()

    queries.each.with_index do |query, i|
      DanbooruRo::Post.raw_tag_match(query).partition(min_date, max_date).each do |result|
        hash[result.date.strftime("%Y-%m-%d")][i] = result.post_count
      end
    end

    hash.to_a.slice(0..-2)
  end

  def date_hash
    (min_date..max_date).to_a.inject({}) {|hash, x| hash[x.to_s] = Array.new(queries.size, 0); hash}
  end

  def validate(sig)
    validate_key(sig)

    if max_date - min_date > 365
      raise ReportError.new("Can only report up to 365 days")
    end
  end

  def validate_key(sig)
    if sig =~ /--/
      verifier = ActiveSupport::MessageVerifier.new(ENV["DANBOORU_SHARED_REMOTE_KEY"], serializer: JSON, digest: "SHA256")
      calc_sig = verifier.generate("#{min_date},#{max_date},#{queries.join(',')}")
    else
      digest = OpenSSL::Digest.new("sha256")
      string = "#{min_date},#{max_date},#{queries.join(',')}"
      calc_sig = OpenSSL::HMAC.hexdigest(digest, , string)
    end

    if calc_sig != sig
      raise VerificationError.new
    end
  end
end
