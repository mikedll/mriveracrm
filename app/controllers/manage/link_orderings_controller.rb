class Manage::LinkOrderingsController < Manage::BaseController

  configure_apps :model => LinkOrdering do
    belongs_to :business
    actions :index, :create, :update
  end

  def create_or_update
    @current_object = current_model.find_by_referenced_link params[:referenced_link]
    if @current_object.nil?
      @current_object = current_model.build(object_parameters)
      @current_object.referenced_link = params[:referenced_link]

      if @current_object.save
        response_for :create
      else
        response_for :create_fails
      end
    else
      if @current_object.update_attributes(object_parameters)
        response_for :update
      else
        response_for :update_fails
      end
    end
  end

  alias_method :create, :create_or_update
  alias_method :update, :create_or_update

  def object_parameters
    params.slice(* apps_configuration[:primary_model].accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  protected

  def _require_business_support
    true # _bsupports?(Feature::Names::CMS)
  end

end
