class Manage::ReportsController < Manage::BaseController

  configure_apps do
    actions :index, :show
  end

  def current_objects
    [:name => "earnings"]
  end

end
