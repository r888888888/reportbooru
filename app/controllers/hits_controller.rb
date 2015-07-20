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
    when /^pv-(\d+)/
      count = HitCounter.new.post_view_count($1.to_i) + 1
      render text: count

    else
      render nothing: true, status: 422
    end
  end
end
