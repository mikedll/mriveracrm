class Manage::BaseController < ApplicationController

  before_filter :require_employee
  before_filter :require_active_plan
  before_filter :_require_business_support
  before_filter :_activate_apps
  before_filter :_configure_apps_base

  protected

  def ssl_required?; Rails.env.production?; end

  def json_config
    {}
  end

  def rendered_current_objects
    current_objects.to_json(json_config)
  end

  def rendered_current_object
    current_object.to_json(json_config)
  end

  def state_transition
    if yield
      response_for :update
    else
      response_for :update_fails
    end
  end

  def _configure_apps_base
    apps_configuration.merge!(:manage => true)
  end

end
