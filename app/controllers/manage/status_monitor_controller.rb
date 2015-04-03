class Manage::StatusMonitorController < Manage::BaseController

  skip_before_filter :require_active_plan
  before_filter :_can_monitor_business

  def show
    respond_to do |f|
      f.html {}
      f.json { render :json => { :status => StatusMonitor.check_stripe(@current_business.stripe_secret_key) } }
    end
  end

  protected

  def _require_business_support
    true
  end

  def _can_monitor_business
    authorize! :monitor, current_business
  end

end
