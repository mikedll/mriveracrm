class Manage::EmployeesController < Manage::BaseController

  before_filter :_parent_name

  make_resourceful do
    actions :new, :index, :show, :update, :create
    belongs_to :business
    response_for :new do
      render :layout => nil
    end

    response_for(:index) do |format|
      format.html
      format.js { render :json => current_objects }
    end

    response_for(:show, :update) do |format|
      format.js { render :json => current_object }
    end

    response_for(:create) do |format|
      format.js { render :status => :created, :json => current_object }
    end

    response_for(:update_fails, :create_fails) do |format|
      format.js { render :status => :unprocessable_entity, :json => { :object => current_object, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  def build_object
    @current_object = current_business.employees.build(object_parameters)
  end

  def object_parameters
    params.slice(* Employee.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  def current_objects
    top_scope = current_model

    @current_objects ||= top_scope.order("updated_at DESC")
  end

  def parent_object
    @parent_object ||= Business.current
  end

  def _parent_name
    @parent_name = "business" # hack; parent_object isnt enough.
  end

end
