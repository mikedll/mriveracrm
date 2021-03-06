class Manage::BusinessesController < Manage::BaseController

  skip_before_filter :require_active_plan
  skip_before_filter :_define_top_query_scope

  before_filter :_can_manage_current_object

  configure_apps :model => Business do
    title "Your Business"
    actions :show, :update, :destroy
    member_actions :regenerate_monitored_computers_key
  end

  def current_object
    @current_object ||= current_business
  end

  def current_objects
    raise "Should not be attempting to load all businesses."
    @current_objects = []
  end

  def regenerate_monitored_computers_api_key
    with_update_and_transition { current_object.cycle_it_monitored_computers_key }
  end

  def update
    before :update
    begin
      current_object.attributes = object_parameters
      current_object.stripe_secret_key =           params[:stripe_secret_key] if params[:stripe_secret_key]
      current_object.stripe_publishable_key =      params[:stripe_publishable_key] if params[:stripe_publishable_key]
      current_object.google_oauth2_client_id =     params[:google_oauth2_client_id] if params[:google_oauth2_client_id]
      current_object.google_oauth2_client_secret = params[:google_oauth2_client_secret] if params[:google_oauth2_client_secret]
      current_object.google_public_api_key =       params[:google_public_api_key] if params[:google_public_api_key]
      current_object.splash_html =                 params[:splash_html] if params[:splash_html]
      result = current_object.save
    rescue ActiveRecord::StaleObjectError
      current_object.reload
      result = false
    end

    if result
      save_succeeded!
      after :update
      response_for :update
    else
      save_failed!
      after :update_fails
      response_for :update_fails
    end
  end

  protected

  def _require_business_support
    true
  end

  def _can_manage_current_object
    authorize! :manage, current_object
  end

end
