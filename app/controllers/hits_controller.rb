class HitsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :enable_cors

  def create
    if params[:key] && params[:value] && params[:sig]
      HitCounter.new.count!(params[:key], params[:value], params[:sig])
      render nothing: true
    else
      render nothing: true, status: 422
    end
  end

  def show
    case params[:id]
    when "day"
      @date = Date.parse(params[:date])
      render text: to_text(HitCounter.new.post_search_rank_day(@date, HitCounter::LIMIT))

    when "week"
      @date = Date.parse(params[:date])
      render text: to_text(HitCounter.new.post_search_rank_week(@date, HitCounter::LIMIT))

    when "year"
      @date = Date.parse(params[:date])
      render text: to_text(HitCounter.new.post_search_rank_year(@date, HitCounter::LIMIT))

    else
      render nothing: true, status: 422
    end
  end

protected
  
  def to_text(results)
    results.map {|x| x.join(" ")}.join("\n")
  end
end
