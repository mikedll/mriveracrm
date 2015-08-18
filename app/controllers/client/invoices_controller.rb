class Client::InvoicesController < Client::BaseController

  configure_apps :model => Invoice, :view => :client do
    actions :index, :show
    member_actions :charge
    belongs_to :client
  end

  def charge
    state_transition { current_object.charge! }
  end

  def parent_object
    @parent_object ||= current_user.client
  end

  def current_model
    parent_object.invoices.viewable_to_client
  end

  protected

  def _require_business_support
    _bsupports?(Feature::Names::INVOICING)
  end

end
