class TagSimilarityCalculator
  SAMPLE_SIZE = 400
  attr_reader :tag_name, :results

  def initialize(tag_name)
    @tag_name = tag_name
  end

  def date_constraint(count)
    if count >= 1_000_000
      1.year.ago.to_date
    elsif count >= 100_000
      2.years.ago.to_date
    elsif count >= 10_000
      4.years.ago.to_date
    else
      16.years.ago.to_date
    end
  end

  def calculate
    tag = DanbooruRo::Tag.find_by_name(tag_name)
    return if tag.nil? || (tag.related_tags_updated_at && tag.related_tags_updated_at >= 24.hours.ago)

    # this uses cosine similarity to produce more useful
    # related tags, but is more db intensive
    counts = Hash.new {|h, k| h[k] = 0}

    DanbooruRo::Post.raw_tag_match(tag_name).limit(SAMPLE_SIZE).reorder("posts.md5").pluck(:tag_string).each do |tag_string|
      tag_string.scan(/\S+/).each do |tag|
        counts[tag] += 1
      end
    end

    candidates = convert_hash_to_array(counts, 100)
    similar_counts = Hash.new {|h, k| h[k] = 0}
    candidates.each do |ctag, _|
      if ctag == tag_name
        similar_counts[ctag] = 1
      else
        acount = DanbooruRo::Post.raw_intersection_tag_match([tag_name, ctag]).where("id >= ?", DanbooruRo::Post.estimate_post_id(date_constraint(tag.post_count))).count
        ctag_count = DanbooruRo::Tag.post_count(ctag)
        div = Math.sqrt(tag.post_count * ctag_count)
        if div != 0
          c = acount / div
          similar_counts[ctag] = c
        end
      end
    end

    @results = convert_hash_to_array(similar_counts)
  end

  def update_danbooru
    params = {
      "key" => ENV["DANBOORU_SHARED_REMOTE_KEY"],
      "name" => tag_name,
      "related_tags" => results.join(" ")
    }
    uri = URI.parse("https://danbooru.donmai.us/related_tag")

    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.is_a?(URI::HTTPS)) do |http|
      http.request_put(uri.request_uri, URI.encode_www_form(params))
    end
  end

private

  def convert_hash_to_array(hash, limit = 25)
    hash.to_a.sort_by {|x| -x[1]}.slice(0, limit)
  end
end
