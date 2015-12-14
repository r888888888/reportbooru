class UploadReport
  attr_reader :min_date, :max_date, :queries

  def initialize(min_date, max_date, queries)
    @min_date = min_date.to_date
    @max_date = max_date.to_date
    @queries = queries
  end

  def chart_data
    queries.map do |query|
      hash = date_hash()

      Post.raw_tag_match(query).partition(min_date, max_date).each do |result|
        hash[result.date.strftime("%Y-%m-%d")] = result.post_count
      end

      dates.to_a
    end
  end

  def date_hash
    (min_date..max_date).to_a.inject({}) {|hash, x| hash[x.to_s] = 0; hash}
  end
end
