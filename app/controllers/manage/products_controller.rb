class Manage::ProductsController < Manage::BaseController

  configure_apps do
    actions :all
    belongs_to :business
    response_for :new do
      render :layout => nil
    end

    response_for(:index) do |format|
      format.html
      format.js { render :json => rendered_current_objects }
    end

    response_for(:show, :update, :destroy) do |format|
      format.json { render :json => rendered_current_object }
    end

    response_for(:create) do |format|
      format.js { render :status => :created, :json => rendered_current_object }
    end

    response_for(:update_fails, :create_fails) do |format|
      format.js { render :status => :unprocessable_entity, :json => { :object => rendered_current_object, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  def json_config
    {:include => { :product_images => { :include => :image } }}
  end

  def current_objects
    top_scope = current_model
    @current_objects ||= top_scope.order("updated_at DESC")
  end

  def object_parameters
    params.slice(* Product.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  protected

  def _require_business_support
    _bsupports?(Feature::Names::PRODUCTS)
  end

end
