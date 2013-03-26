class Client::BaseController < ApplicationController
  before_filter :require_client

  protected

  def ssl_required?; Rails.env.production?; end
  
end
