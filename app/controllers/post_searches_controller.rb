class PostSearchesController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :enable_cors
  rescue_from Concerns::RedisCounter::VerificationError, :with => :render_verification_error
  rescue_from ActiveSupport::MessageVerifier::InvalidSignature, with: :render_verification_error

  def create
    if params[:msg]
      tags, session_id = verify_msg(params[:msg])
      SearchCounter.new.count!(tags, session_id)
      render nothing: true
    else
      render nothing: true, status: 422
    end
  end

  def show
    if params[:id] == "rank"
      @date = Date.parse(params[:date]).to_s
      render text: SearchCounter.new.get_rank(@date, HitCounter::LIMIT).to_json
    else
      render text: SearchCounter.new.get_count(params[:id]).to_s
    end
  end

protected

  def verify_msg(msg)
    verifier = ActiveSupport::MessageVerifier.new(ENV["DANBOORU_SHARED_REMOTE_KEY"], serializer: JSON, digest: "SHA256")
    res = verifier.verify(msg)
    tags, session_id = res.split(/,/)
    [tags, session_id]
  end
end
