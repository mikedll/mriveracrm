class Client::PaymentGatewayProfilesController < Client::BaseController

  make_resourceful do
    actions :update, :show

    response_for(:show) do |format|
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

  def current_object
    @current_object ||= current_user.client.payment_gateway_profile
  end

end
