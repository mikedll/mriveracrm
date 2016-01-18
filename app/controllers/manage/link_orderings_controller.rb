class Manage::LinkOrderingsController < Manage::BaseController

  configure_apps :model => LinkOrdering do
    belongs_to :business
    actions :index, :update
  end

  protected

  def _require_business_support
    true # _bsupports?(Feature::Names::CMS)
  end

end
