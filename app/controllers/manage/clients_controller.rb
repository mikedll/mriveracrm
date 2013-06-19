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
    top_scope = current_model
    if params[:archived].blank?
      top_scope = top_scope.unarchived 
    else
      top_scope = top_scope.archived
    end
    top_scope = top_scope.recently_modified if params[:recently_modified].blank?
    @current_objects ||= top_scope.order("updated_at DESC")
  end

  def archive
    with_update_and_transition { current_object.archive! }
  end

  def unarchive
    with_update_and_transition { current_object.unarchive! }
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

  def with_update_and_transition
    load_object
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


end
