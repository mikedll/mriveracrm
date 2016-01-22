class Manage::PagesController < Manage::BaseController

  configure_apps :model => Page do
    belongs_to :business
    include_model_template LinkOrdering
    include_bootstrap :link_orderings, :has_defaults => true
    actions :index, :create, :show, :destroy, :update
  end

  def parent_object
    @parent_object ||= current_business
  end

  def object_parameters
    params.slice(* apps_configuration[:primary_model].accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  protected

  def _require_business_support
    true # _bsupports?(Feature::Names::CMS)
  end

end
