class Manage::BusinessesController < Manage::BaseController

  skip_before_filter :require_active_plan

  make_resourceful do
    actions :show, :update, :destroy

    response_for :destroy do |format|
      format.html
      format.json { render :json => current_object }
    end

    response_for(:show, :update) do |format|
      format.html
      format.json { render :json => current_object }
    end

    response_for(:update_fails) do |format|
      format.json { render :status => :unprocessable_entity, :json => { :object => current_object, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  def current_object
    @current_object ||= @current_business
  end

  def current_objects
    raise "Should not be attempting to load all businesses."
    @current_objects = []
  end

  def update
    before :update
    begin
      current_object.name = params[:name] if params[:name]
      current_object.stripe_secret_key = params[:stripe_secret_key] if params[:stripe_secret_key]
      current_object.stripe_publishable_key = params[:stripe_publishable_key] if params[:stripe_publishable_key]
      current_object.google_oauth2_client_id = params[:google_oauth2_client_id] if params[:google_oauth2_client_id]
      current_object.google_oauth2_client_secret = params[:google_oauth2_client_secret] if params[:google_oauth2_client_secret]
      current_object.splash_html = params[:splash_html] if params[:splash_html]
      # current_object. = params[:] if params[:]
      # current_object. = params[:] if params[:]
      # current_object. = params[:] if params[:]
      # current_object. = params[:] if params[:]
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

  def object_parameters
    [] # too worried about mass assignment
  end

  protected

  def _require_business_support
    true
  end

end
