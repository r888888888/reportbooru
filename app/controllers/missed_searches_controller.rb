class MissedSearchesController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :enable_cors
  rescue_from Concerns::RedisCounter::VerificationError, :with => :render_verification_error

  def create
    if params[:tags] && params[:session_id] && params[:sig]
      MissedSearchCounter.new.count!(params[:tags], params[:session_id], params[:sig])
      render nothing: true
    else
      render nothing: true, status: 422
    end
  end

  def show
    headers["Content-Type"] = "text/plain; charset=UTF-8" 
    render text: to_text(MissedSearchCounter.new.rank)
  end

protected
  def render_verification_error
    render :text => "provided signature is invalid", :status => :forbidden
  end
  
  def to_text(results)
    results.map {|x| x.join(" ")}.join("\n")
  end
end
