class Manage::ProductsController < Manage::BaseController

  before_filter :_parent_name

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
      format.json { render :json => current_object }
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
    @current_objects ||= top_scope.order("updated_at DESC")
  end

  def build_object
    @current_object = current_business.products.build(object_parameters)
  end

  def object_parameters
    params.slice(* Product.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  def parent_object
    @parent_object ||= Business.current
  end

  def _parent_name
    @parent_name = "business" # hack; parent_object isnt enough.
  end

end