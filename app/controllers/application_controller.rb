class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authenticate, :if => lambda { |x| !Rails.env.development? }
  
  private
  
  def authenticate
    authenticate_or_request_with_http_basic("Jeocrowd") do |username, password|
      username == "jeo" && password == "cr0wd"
    end
  end
end
