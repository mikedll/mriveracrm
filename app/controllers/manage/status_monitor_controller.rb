class Manage::StatusMonitorController < Manage::BaseController

  def show
    respond_to do |f|
      f.html {}
      f.json { render :json => { :status => StatusMonitor.check_stripe(@current_business.stripe_secret_key) } }
    end
  end

end
