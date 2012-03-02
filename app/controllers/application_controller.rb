class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authenticate, :if => lambda { |x| !Rails.env.development? }
  before_filter :set_session_vars
  
  private
  
  def authenticate
    authenticate_or_request_with_http_basic("Jeocrowd") do |username, password|
      username == "jeo" && password == "cr0wd"
    end
  end
  
  def set_session_vars
    session[:show_benchmark_bars] = params[:show_benchmark_bars].to_s == "true" ? true : false
    session[:show_time] = params[:show_time].to_s == "true" ? true : false    
  end
end
