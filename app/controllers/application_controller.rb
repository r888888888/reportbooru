class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

protected

  def enable_cors
    response.headers["Access-Control-Allow-Origin"] = "*"
  end

  def render_422
    render nothing: true, status: 422
  end
end
