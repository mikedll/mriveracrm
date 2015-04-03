class Client::PaymentGatewayProfilesController < Client::BaseController

  before_filter :create_remote_if_doesnt_exist, :only => [:create, :update]

  make_resourceful do
    actions :update, :show

    response_for(:show, :update) do |format|
      format.js { render :json => current_object.public }
    end

    response_for(:update_fails) do |format|
      format.js { render :status => :unprocessable_entity, :json => { :object => current_object.public, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  def update
    if current_object.update_payment_info(params.slice(:card_number, :expiration_month, :expiration_year, :cv_code))
      response_for :update
    else
      response_for :update_fails
    end
  end

  alias_method :create, :update

  def create_remote_if_doesnt_exist
    current_user.client.require_payment_gateway_profile if current_user.client.payment_gateway_profile.nil?
    if current_user.client.payment_gateway_profile.nil?
      render :status => :unprocessable_entity, :json => { :full_messages => [t('payment_gateway_profile.update_error')] }
      return
    end
  end

  def current_object
    @current_object ||= current_user.client.payment_gateway_profile
  end

  protected

  def _require_business_support
    _bsupports?(Feature::Names::INVOICING)
  end

end
