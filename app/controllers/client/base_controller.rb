class Client::BaseController < ApplicationController
  before_filter :require_client
  before_filter :require_active_plan_public
  before_filter :_require_business_support

  protected

  def ssl_required?; Rails.env.production?; end

end
