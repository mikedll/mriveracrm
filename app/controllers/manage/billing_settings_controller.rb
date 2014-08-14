class Manage::BillingSettingsController < Manage::BaseController

  make_resourceful do
    actions :show, :update, :destroy

    response_for :destroy do |format|
      format.html
      format.json { render :json => current_object.renderable_json }
    end

    response_for(:show, :update) do |format|
      format.html
      format.json { render :json => current_object.renderable_json }
    end

    response_for(:update_fails) do |format|
      format.json { render :status => :unprocessable_entity, :json => { :object => current_object.renderable_json, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
    end
  end

  def current_object
    @current_object ||= @current_business.usage_subscription
  end

  def current_objects
    raise "Should not be attempting to load all business settings."
    @current_objects = []
  end

  def update
    if current_object.payment_gateway_profile.nil?
      current_object.require_payment_gateway_profile
      if current_object.payment_gateway_profile.nil?
        render :status => :unprocessable_entity, :json => { :full_messages => [t('usage_subscriptions.no_payment_gateway_profile')] }
        return
      end
    end

    before :update
    begin
      result = current_object.payment_gateway_profile.update_payment_info((params[:billing_settings] || {})[:payment_gateway_profile] || {})
    rescue ActiveRecord::StaleObjectError
      current_object.reload
      result = false
    end

    if current_object.payment_gateway_profile.changed? && !result
      save_failed!
      after :update_fails
      response_for :update_fails
      return
    end

    # we dont use a transaction. we'll allow a second phase of errors, after the card update.

    begin
      result = current_object.update_attributes(object_parameters)
    rescue ActiveRecord::StaleObjectError
      current_object.reload
      result = false
    end

    if result
      save_succeeded!
      after :update
      response_for :update
    else
      save_failed!
      after :update_fails
      response_for :update_fails
    end

  end

  def object_parameters
    params.slice(* UsageSubscription.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

end
