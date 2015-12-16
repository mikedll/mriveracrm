class MonitoredComputersController < ApplicationController

  skip_before_filter :verify_authenticity_token

  skip_before_filter :authenticate_user!
  before_filter :require_active_plan_public
  before_filter :_require_business_support

  def heartbeat
    head :ok
  end

  def _require_business_support
    true # _bsupports?(Feature::Names::IT_MONITOR)
  end

end
