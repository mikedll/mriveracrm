class Manage::LinkOrderingsController < Manage::BaseController

  configure_apps :model => LinkOrdering do
    belongs_to :business
    actions :index, :create, :update
  end

  def object_parameters
    params.slice(* apps_configuration[:primary_model].accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  protected

  def _require_business_support
    true # _bsupports?(Feature::Names::CMS)
  end

end
