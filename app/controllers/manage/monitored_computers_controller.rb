class Manage::MonitoredComputersController < Manage::BaseController

  configure_apps :model => ::IT::MonitoredComputer do
    actions :index, :show, :create, :update, :destroy
    belongs_to :business
  end

  skip_before_filter :require_active_plan

  def object_parameters
    params.slice(* IT::MonitoredComputer.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  def parent_object
    @parent_object ||= current_business
  end

  protected

  def _require_business_support
    true # _bsupports?(Feature::Names::IT_MONITOR)
  end

end
