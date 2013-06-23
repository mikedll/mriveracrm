class Manage::StatusMonitorController < Manage::BaseController

  def show
    respond_to do |f|
      f.html {}
      f.json { render :json => { :status => StatusMonitor.check_stripe } }
    end
  end

end
