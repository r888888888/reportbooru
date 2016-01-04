class TagSimilarityCalculator
  SAMPLE_SIZE = 400
  attr_reader :name, :results

  def initialize(name)
    @name = name
  end

  def calculate
    # this uses cosine similarity to produce more useful
    # related tags, but is more db intensive
    counts = Hash.new {|h, k| h[k] = 0}

    Post.raw_tag_match(tag).limit(SAMPLE_SIZE).reorder("posts.md5").pluck(:tag_string).each do |tag_string|
      tag_string.scan(/\S+/).each do |tag|
        counts[tag] += 1
      end
    end

    tag_record = Tag.post_count(name)
    candidates = convert_hash_to_array(counts, 100)
    similar_counts = Hash.new {|h, k| h[k] = 0}
    candidates.each do |ctag, _|
      acount = Post.raw_intersection_tag_match(tag, ctag).count
      ctag_count = Tag.post_count(ctag)
      div = Math.sqrt(tag_record.post_count * ctag_count)
      if div != 0
        c = acount / div
        similar_counts[ctag] = c
      end
    end

    @results = convert_hash_to_array(similar_counts)
  end

  def update_danbooru
    params = {
      "key" => Rails.application.config.x.shared_remote_key,
      "name" => name,
      "related_tags" => results.join(" ")
    }
    uri = URI.parse("https://danbooru.donmai.us/related_tag")

    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.is_a?(URI::HTTPS)) do |http|
      http.request_post(uri.request_uri, URI.encode_www_form(params))
    end
  end

private

  def convert_hash_to_array(hash, limit = 25)
    hash.to_a.sort_by {|x| -x[1]}.slice(0, limit)
  end
end
