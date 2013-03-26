class Manage::BaseController < ApplicationController

  before_filter :require_employee

  protected

  def ssl_required?; Rails.env.production?; end

end
