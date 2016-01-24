class Manage::ReportsController < Manage::BaseController

  configure_apps do
    actions :index, :show
  end

  def current_objects
    @current_objects ||= [{ :name => "earnings"}]
  end

  def _require_business_support
    true # we may add advanced reporting later.
  end

end
