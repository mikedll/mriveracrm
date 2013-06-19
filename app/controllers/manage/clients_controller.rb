class Manage::ClientsController < Manage::BaseController

  make_resourceful do
    actions :all
    belongs_to :business
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

    response_for(:update_fails, :create_fails) do |format|
      format.js { render :status => :unprocessable_entity, :json => { :object => current_object, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  def current_objects
    @current_objects ||= current_model.unarchived.order("updated_at DESC")
  end

  def archive
    load_object
    if current_object.update_attributes(object_parameters)
      if current_object.archive!
        response_for :update
      else
        response_for :update_fails
      end
    else
      response_for :update_fails
    end
  end

  def build_object
    @current_object = current_business.clients.build(object_parameters)
  end

  def object_parameters
    params.slice(* Client.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  def parent_object
    @parent_object ||= Business.current
  end

end
