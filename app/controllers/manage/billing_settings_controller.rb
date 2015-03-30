class Manage::BillingSettingsController < Manage::BaseController

  skip_before_filter :require_active_plan

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

    response_for :payment_info_update_fails do |format|
      format.json { render :status => :unprocessable_entity, :json => { :object => current_object.payment_gateway_profile.public, :errors => current_object.payment_gateway_profile.errors, :full_messages => current_object.payment_gateway_profile.errors.full_messages} }
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

    payment_params = params[:payment_gateway_profile_attributes] || {}
    if !payment_params.values.all? { |v| v.blank? }

      result = false
      begin
        result = current_object.payment_gateway_profile.update_payment_info(payment_params)
      rescue ActiveRecord::StaleObjectError
        current_object.reload
        result = false
      end

      if !result
        save_failed!
        after :update_fails
        response_for :payment_info_update_fails
        return
      end
    end

    # we dont use a transaction. we'll allow a second phase of errors, after the card update.
    result = true
    begin
      current_object.attributes = object_parameters
      current_object.feature_selections_attributes = params[:feature_selections_attributes] # this isnt in attr accessible
      result = current_object.save
    rescue ActiveRecord::StaleObjectError
      current_object.reload
      result = false
    end

    if result
      current_object.reload # this is a hack to capture the profile save...
      # the profile doesn't adjust the same object here, so we have to reload
      # it from the database. the polymorphic relationship prevents us from
      # doing an inverse_of...

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

  protected

  def _require_business_support
    true
  end

end
