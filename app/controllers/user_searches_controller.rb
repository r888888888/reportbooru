class UserSearchesController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :enable_cors

  def show
    headers["Content-Type"] = "text/plain; charset=UTF-8" 
    @searches = HitCounter.new.post_search_by_user(params[:uid].to_i, params[:sig])
    render layout: false
  end

protected
  def render_verification_error
    render :text => "provided signature is invalid", :status => :forbidden
  end
end
