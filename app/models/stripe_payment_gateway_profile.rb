class StripePaymentGatewayProfile < PaymentGatewayProfile

  scope :by_vendor_id, lambda { |id| where("vendor_id = ?", id) }
  scope :with_payment_gateway_profilable, lambda { joins(:payment_gateway_profilable).where('payment_gateway_profilable_type = ?', 'usage_subscription') }

  class NoStripeApiKey < Exception
  end

  module Events
    SUBSCRIPTION_UPDATED = 'customer.subscription.updated'
  end

  class Worker < WorkerBase
  end

  def public
    {
      :id => id,
      :card_prompt => card_prompt,
      :updated_at => updated_at,
      :available_for_request? => available_for_request?
    }
  end

  def ready_for_payments?
    !self.vendor_id.nil? && !self.card_last_4.blank?
  end

  def subscribable?
    payment_gateway_profilable.payment_gateway_profilable_subscribable?
  end

  def active_plan?
    payment_gateway_profilable.payment_gateway_profilable_subscribable?
    [self.class::Status::TRIALING,
      self.class::Status::ACTIVE].any? { |s| s == stripe_status }
  end

  def remote_status
    stripe_status
  end

  def trial_ends_at
    stripe_trial_ends_at
  end

  NOT_FOUND_MESSAGE = "No such event: "
  def webhook_event_with_stripe_key(key, id)
    event = nil

    _with_stripe_key(key) do
      begin
        event = Stripe::Event.retrieve id
      rescue Stripe::InvalidRequestError => e
        if e.message.include?(NOT_FOUND_MESSAGE)
          event = nil
        else
          raise e
        end
      end
    end

    event
  end

  def pay_invoice!(amount, description)
    result = { :error => '', :succeeded => false, :vendor_id => nil }

    _with_stripe_key do
      charge = nil
      begin
        charge = Stripe::Charge.create({
                                         :customer => vendor_id,
                                         :amount => (amount * 100).to_i,
                                         :currency => "usd",
                                         :description => description
                                       })
      rescue Stripe::CardError => e
        result[:error] = e.message
        return result
      end

      result[:vendor_id] = charge.id
      if !charge[:captured]
        # unknown as to whether this can ever be reached
        result[:error] = charge[:failure_message]
        return result
      end

      result[:succeeded] = true
      result
    end
  end

  UPDATE_PAYMENT_INFO_REQUEST = 'update_payment_info'
  def update_payment_info(options)
    card_params = nil
    if options[:token].blank?
      card = card_from_options(options)
      return false if !card_valid?(card)
      card_params = {
        :number => card.number,
        :exp_month => card.month,
        :exp_year => card.year,
        :cvc => card.verification_value
      }
    else
      card_params = options[:token]
    end

    Worker.obj_enqueue(self, :update_payment_info_background, card_params) if start_persistent_request(UPDATE_PAYMENT_INFO_REQUEST)
  end

  def update_payment_info_background(card_params)
    _with_stop_persistence(UPDATE_PAYMENT_INFO_REQUEST) do
      _create_remote if vendor_id.blank?

      _with_stripe_key do
        customer = Stripe::Customer.retrieve(self.vendor_id)

        customer.card = card_params

        begin
          customer.save
        rescue Stripe::CardError => e
          self.last_error = e.message
          return false
        rescue Stripe::InvalidRequestError => e
          DetectedError.create!(:message => "Stripe profile update failure: #{e.message}.", :client_id => payment_gateway_profilable_id)
          self.last_error = I18n.t('payment_gateway_profile.update_error')
          return false
        rescue => e
          DetectedError.create!(:message => "Very strange stripe profile exception thrown: #{e.message}.", :client_id => payment_gateway_profilable_id)
          self.last_error = I18n.t('payment_gateway_profile.update_error')
          return false
        end

        _cache_customer(customer)
        save!
      end
    end
  end


  RECOGNIZED_ERRORS = [
    "Failed to create",
    "This customer has no attached payment source"
  ]

  #
  # The profilable is because Rails isn't smart enough
  # to load the exact same cached object.
  #
  def update_plan!(plan_id, profilable = payment_gateway_profilable)
    raise "Inequivalence beyond object identity, profilable != payment_gateway_profilable" if profilable != payment_gateway_profilable

    _with_stripe_key do
      customer = Stripe::Customer.retrieve(self.vendor_id)

      begin
        if customer.subscriptions.data.empty?
          result = customer.subscriptions.create(:trial_end => (Time.now + self.class::TRIAL_DURATION).to_i,
                                                 :plan => plan_id)
        else
          sub = customer.subscriptions.data.first
          sub.plan = plan_id
          sub.trial_end = stripe_trial_ends_at.to_i if trialing?
          sub.save
        end
      rescue Stripe::InvalidRequestError => e
        if RECOGNIZED_ERRORS.any? { |m| e.message.start_with?(m) }
          profilable.errors.add(:base, I18n.t('payment_gateway_profile.custom_plan_update_error', :message => e.message))
        else
          profilable.errors.add(:base, I18n.t('payment_gateway_profile.plan_update_error'))
          DetectedError.create(:message => e.message, :business_id => profilable.business_id)
        end

        return false
      end

      customer = Stripe::Customer.retrieve(self.vendor_id)
      _cache_customer(customer)
      save
    end
  end

  STRIPE_INTERVALS = {
    'month' => 'month'
  }

  STRIPE_CURRENCIES = {
    'usd' => 'usd'
  }

  def ensure_plan_created!(plan_id, price)
    _with_stripe_key do

      plan = nil
      begin
        plan = Stripe::Plan.retrieve plan_id
      rescue Stripe::InvalidRequestError => e
        if e.message.start_with?("No such plan:")
          plan = nil
        else
          raise e
        end
      end

      if plan.nil?
        plan = Stripe::Plan.create(:id => plan_id,
                                   :amount => (price * 100).to_i,
                                   :currency => STRIPE_CURRENCIES['usd'],
                                   :interval => STRIPE_INTERVALS['month'],
                                   :name => plan_id)
      end

      plan
    end
  end

  ERASE_SENSITIVE_INFORMATION_REQUEST = 'erase_sensitive_information_request'
  def erase_sensitive_information!
    return true if self.vendor_id.blank?

    _with_stop_persistence(ERASE_SENSITIVE_INFORMATION_REQUEST) do
      _with_stripe_key do
        customer = Stripe::Customer.retrieve(vendor_id)
        ids = customer.sources.data.map { |d| d.id }
        ids.each do |source_id|
          resp = customer.sources.retrieve(source_id).delete
        end

        customer = Stripe::Customer.retrieve(vendor_id)
        _cache_customer(customer)
        save
      end
    end
  end

  def reload_remote
    if self.vendor_id.blank?
      DetectedErrors.create(:message => "Reloading but no vendor id", :client_id => payment_gateway_profilable_id)
      return
    end
    customer = nil
    _with_stripe_key do
      customer = Stripe::Customer.retrieve(self.vendor_id)
    end
    _cache_customer(customer)
    save!
  end

  protected

  def _create_remote
    return if payment_gateway_profilable.payment_gateway_profilable_remote_app_key.blank?

    customer = nil
    _with_stripe_key do
      customer = Stripe::Customer.create(payment_gateway_profilable.payment_gateway_profilable_desc_attrs)
    end

    self.vendor_id = customer.id
    _cache_customer(customer)
    save!
  end

  def _cache_customer(customer)
    if customer[:active_card]
      self.card_last_4 = customer[:active_card][:last4]
      self.card_brand = customer[:active_card][:type]
    else
      self.card_last_4 = ""
      self.card_brand = ""
    end

    if !customer.subscriptions.data.empty?
      sub = customer.subscriptions.data.first

      if !sub.trial_end.nil?
        self.stripe_trial_ends_at = Time.zone.at(sub.trial_end)
      else
        self.stripe_trial_ends_at = nil
      end

      if sub.current_period_end
        self.stripe_current_period_ends_at = Time.zone.at(sub.current_period_end)
      else
        self.stripe_current_period_ends_at = nil
      end

      self.stripe_status = sub.status
      self.stripe_plan = sub.plan.id
    end
  end

  def _with_stripe_key(key = nil)
    begin
      raise "Stripe api key was not blank. Probably a bug." if Stripe.api_key != ""

      Stripe.api_key = key ? key : payment_gateway_profilable.payment_gateway_profilable_remote_app_key

      yield
    ensure
      Stripe.api_key = ""
    end
  end

end
