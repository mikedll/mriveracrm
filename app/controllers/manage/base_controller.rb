class Manage::BaseController < ApplicationController

  before_filter :require_employee
  before_filter :require_active_plan
  before_filter :_require_business_support
  before_filter :_activate_apps
  before_filter :_configure_apps_base

  make_resourceful do
    # Provide our own defaults.
    # We use rendered_current_object instead of make_resourceful's publish,
    # finding it too limited. We have some tricky scenarios I think where
    # we have to render an array of object to a string and hand it to
    # the view directly, which doesn't work well with make_resourceful's
    # publish. This can be revisited, though.

    response_for :new do
      render :layout => nil
    end

    response_for(:index) do |format|
      format.html do
        apps_configuration.merge!(:bootstrap => rendered_current_objects)
        render :template => "app_container"
      end
      format.json { render :json => rendered_current_objects }
    end

    response_for(:show) do |format|
      format.html do
        apps_configuration.merge!({
            :bootstrap => rendered_current_object,
            :app_class => apps_configuration[:app_class].underscore.camelize.singularize.underscore.dasherize # thank you
        })
        render :template => "app_container"
      end
      format.json { render :json => rendered_current_object }
    end

    response_for(:update, :destroy) do |format|
      format.json { render :json => rendered_current_object }
    end

    response_for(:create) do |format|
      format.json { render :status => :created, :json => rendered_current_object }
    end

    response_for(:update_fails, :create_fails) do |format|
      format.json { render :status => :unprocessable_entity, :json => { :object => rendered_current_object, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  protected

  def with_update_and_transition
    if current_object.update_attributes(object_parameters)
      if yield
        response_for :update
      else
        response_for :update_fails
      end
    else
      response_for :update_fails
    end
  end

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
