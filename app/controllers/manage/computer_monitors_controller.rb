class Manage::ComputerMonitorsController < Manage::BaseController

  configure_apps :model => ::IT::ComputerMonitor

  skip_before_filter :require_active_plan

  before_filter :_parent_name

  make_resourceful do
    actions :index, :show, :create, :update, :destroy
    member_actions :rank
    belongs_to :business
  end

  def json_config
    { :methods => [:available_for_request?] }
  end

  def rank
    with_update_and_transition { current_object.rank! }
  end

  def object_parameters
    params.slice(* IT::ComputerMonitor.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

  def parent_object

    puts "*************** #{__FILE__} #{__LINE__} *************"
    puts "#{self.class.made_resourceful?}"


    @parent_object ||= current_business
  end

  protected

  def _parent_name
    @parent_name = "business" # hack; parent_object isnt enough.
  end

  def _require_business_support
    true # _bsupports?(Feature::Names::IT_MONITOR)
  end

end
