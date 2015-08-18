class Manage::BaseController < ApplicationController

  before_filter :require_employee
  before_filter :require_active_plan
  before_filter :_require_business_support

  protected

  def ssl_required?; Rails.env.production?; end

end
