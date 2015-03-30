class Manage::InvitationsController < Manage::BaseController

  make_resourceful do
    actions :index, :show, :update, :create, :destroy
    belongs_to :client
    response_for :new do
      render :layout => nil
    end

    response_for(:index) do |format|
      format.html
      format.js { render :json => current_objects }
    end

    response_for(:show, :update, :destroy) do |format|
      format.js { render :json => current_object }
    end

    response_for(:create) do |format|
      format.js { render :status => :created, :json => current_object }
    end

    response_for(:update_fails, :create_fails, :destroy_fails) do |format|
      format.js { render :status => :unprocessable_entity, :json => { :object => current_object, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  def object_parameters
    params.slice(* Invitation.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  protected

  def _require_business_support
    _bsupports?(Feature::Names::CLIENTS)
  end

end

