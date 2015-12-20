class Manage::BaseController < ApplicationController

  before_filter :require_employee
  before_filter :require_active_plan
  before_filter :_require_business_support

  before_filter :_install_parent_name

  protected

  def _install_parent_name
    @parent_name = "business" # hack; parent_object isnt enough. this also fixes a huge security short-coming
    # of parent? and current_model_name? where a klass is used instead of the parent object. M. Rivera 12/16/15.
  end

  def ssl_required?; Rails.env.production?; end

end
