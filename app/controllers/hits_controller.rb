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
      render text: HitCounter.new.post_search_rank_day(@date, HitCounter::LIMIT).join(" ")

    when "week"
      @date = Date.parse(params[:date])
      render text: HitCounter.new.post_search_rank_week(@date, HitCounter::LIMIT).join(" ")

    when "year"
      @date = Date.parse(params[:date])
      render text: HitCounter.new.post_search_rank_year(@date, HitCounter::LIMIT).join(" ")

    else
      render nothing: true, status: 422
    end
  end
end
