class Client::InvoicesController < Client::BaseController

  make_resourceful do
    actions :index

    response_for(:index) do |format|
      format.html
      format.js { render :json => current_objects }
    end

    response_for(:show, :update) do |format|
      format.js { render :json => current_object.public }
    end

    response_for(:update_fails) do |format|
      format.js { render :status => :unprocessable_entity, :json => { :object => current_object.public, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  def charge
    if current_object.charge!
      response_for :update
    else
      response_for :update_fails
    end
  end

  def current_objects
    @current_objects ||= current_user.client.invoices.viewable_to_client.map(&:public)
  end

  protected

  def _require_business_support
    _bsupports?(Feature::Names::INVOICING)
  end

end
