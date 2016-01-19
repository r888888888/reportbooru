class HitsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :enable_cors
  rescue_from HitCounter::VerificationError, :with => :render_verification_error

  def create
    if params[:key] && params[:value] && params[:sig]
      HitCounter.new.count!(params[:key], params[:value], params[:sig])
      render nothing: true
    else
      render nothing: true, status: 422
    end
  end

  def show
    @date = Date.parse(params[:date])

    case params[:id]
    when "day"
      render text: to_text(HitCounter.new.post_search_rank_day(@date, HitCounter::LIMIT))

    when "week"
      render text: to_text(HitCounter.new.post_search_rank_week(@date, HitCounter::LIMIT))

    when "month"
      render text: to_text(HitCounter.new.post_search_rank_month(@date, HitCounter::LIMIT))

    else
      render nothing: true, status: 422
    end
  end

protected
  def render_verification_error
    render :text => "provided signature is invalid", :status => :forbidden
  end
  
  def to_text(results)
    results.map {|x| x.join(" ")}.join("\n")
  end
end
