class MissedSearchesController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :enable_cors
  rescue_from Concerns::RedisCounter::VerificationError, :with => :render_verification_error
  rescue_from ActiveSupport::MessageVerifier::InvalidSignature, with: :render_verification_error

  def create
    if params[:sig]
      tags, session_id = verify_msg(params[:sig])
      MissedSearchCounter.new.count!(tags, session_id)
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
  def verify_msg(msg)
    verifier = ActiveSupport::MessageVerifier.new(ENV["DANBOORU_SHARED_REMOTE_KEY"], serializer: JSON, digest: "SHA256")
    res = verifier.verify(msg)
    tags, session_id = res.split(/,/)
    [tags, session_id]
  end

  def render_verification_error
    render :text => "provided signature is invalid", :status => :forbidden
  end
  
  def to_text(results)
    results.map {|x| x.join(" ")}.join("\n")
  end
end
