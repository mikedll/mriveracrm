class Manage::BillingSettingsController < Manage::BaseController

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
    @current_object ||= nil
  end

  def current_objects
    raise "Should not be attempting to load all business settings."
    @current_objects = []
  end

  def update
    before :update
    begin
      current_object.name = params[:name] if params[:name]
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

end
