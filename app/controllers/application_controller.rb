class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

protected

  def check_key
    if params[:key] != Rails.application.config.x.shared_remote_key
      render nothing: true, status: 403
      return false
    end
  end

  def enable_cors
    response.headers["Access-Control-Allow-Origin"] = "*"
  end

  def render_422
    render nothing: true, status: 422
  end
end
