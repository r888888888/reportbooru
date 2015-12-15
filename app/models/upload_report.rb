class UploadReport
  attr_reader :min_date, :max_date, :queries, :scale

  def initialize(min_date, max_date, queries, scale)
    @min_date = min_date.to_date
    if max_date == "today"
      @max_date = Date.today
    else
      @max_date = max_date.to_date
    end
    @queries = queries
    @scale = scale

    if scale == "week"
      @min_date = 1.week.since(@min_date)
      @max_date = 1.week.ago(@max_date)
    end
  end

  def chart_data
    hash = date_hash()

    queries.each.with_index do |query, i|
      Post.raw_tag_match(query).partition(min_date, max_date, scale).each do |result|
        hash[result.date.strftime("%Y-%m-%d")][i] = result.post_count
      end
    end

    hash.to_a.slice(0..-2)
  end

  def date_hash
    if scale == "day"
      (min_date..max_date).to_a.inject({}) {|hash, x| hash[x.to_s] = Array.new(queries.size, 0); hash}
    else
      (min_date..max_date).to_a.select {|x| x.wday == 1}.inject({}) {|hash, x| hash[x.to_s] = Array.new(queries.size, 0); hash}
    end
  end
end
