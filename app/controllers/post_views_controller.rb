class PostViewsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :enable_cors
  rescue_from Concerns::RedisCounter::VerificationError, :with => :render_verification_error
  rescue_from ActiveSupport::MessageVerifier::InvalidSignature, with: :render_verification_error

  def create
    if params[:msg]
      post_id, session_id = verify_msg(params[:msg])
      ViewCounter.new.count!(post_id, session_id)
      render nothing: true
    else
      render nothing: true, status: 422
    end
  end

  def show
    case params[:id]
    when "rank"
      @date = Date.parse(params[:date]).to_s
      render text: ViewCounter.new.get_rank(@date, HitCounter::LIMIT).to_json

    when /\d+/
      render text: ViewCounter.new.get_count(params[:id]).to_s

    else
      render nothing: true, status: 422
    end
  end

protected

  def verify_msg(msg)
    verifier = ActiveSupport::MessageVerifier.new(ENV["DANBOORU_SHARED_REMOTE_KEY"], serializer: JSON, digest: "SHA256")
    res = verifier.verify(msg)
    post_id, session_id = res.split(/,/)
    [post_id.to_i, session_id]
  end
end
