class MonitoredComputersController < ApplicationController

  skip_before_filter :verify_authenticity_token

  skip_before_filter :authenticate_user!
  before_filter :require_active_plan_public
  before_filter :_require_business_support

  def heartbeat
    ip = request.ip
    stats = { :free => params[:free].to_i, :total => params[:total].to_i }

    mc = current_business.it_monitored_computers.find_by_hostname ip
    mc = current_business.it_monitored_computers.build(:hostname => ip, :name => ip) if mc.nil?
    mc.last_heartbeat_received_at = Time.now
    mc.last_result = stats.to_json
    mc.down = false
    if mc.save
      head :ok
    else
      head :unprocessible_entity
    end
  end

  def _require_business_support
    true # _bsupports?(Feature::Names::IT_MONITOR)
  end

end
