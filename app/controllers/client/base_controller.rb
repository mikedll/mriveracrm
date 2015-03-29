class Client::BaseController < ApplicationController
  before_filter :require_client
  before_filter :require_active_plan_public

  protected

  def ssl_required?; Rails.env.production?; end

end
