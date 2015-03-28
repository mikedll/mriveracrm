class StripePaymentGatewayProfile < PaymentGatewayProfile

  scope :by_vendor_id, lambda { |id| where("vendor_id = ?", id) }
  scope :with_payment_gateway_profilable, lambda { joins(:payment_gateway_profilable).where('payment_gateway_profilable_type = ?', 'usage_subscription') }

  class NoStripeApiKey < Exception
  end

  module Events
    SUBSCRIPTION_UPDATED = 'customer.subscription.updated'
  end

  def public
    {
      :id => id,
      :card_prompt => card_prompt,
      :updated_at => updated_at
    }
  end

  def can_pay?
    !self.vendor_id.nil? && !self.card_last_4.blank?
  end

  def subscribable?
    payment_gateway_profilable.payment_gateway_profilable_subscribable?
  end

  def active_plan?
    payment_gateway_profilable.payment_gateway_profilable_subscribable?
    [UsageSubscription::Status::TRIALING,
      UsageSubscription::Status::ACTIVE].any? { |s| s == stripe_status }
  end

  def trialing?
    !stripe_trial_ends_at.nil? && stripe_trial_ends_at > Time.zone.now
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

  def pay_invoice!(invoice)
    if !can_pay?
      self.last_error = I18n.t('payment_gateway_profile.cant_pay')
      return false
    end

    if !invoice.can_pay?
      self.last_error = I18n.t('invoice.cannot_pay')
      return false
    end

    _with_stripe_key do
      transaction = StripeTransaction.new
      transaction.payment_gateway_profile = self
      transaction.invoice = invoice
      transaction.amount = invoice.total
      transaction.begin!

      charge = nil
      begin
        charge = Stripe::Charge.create({
                                         :customer => vendor_id,
                                         :amount => (invoice.total * 100).to_i,
                                         :currency => "usd",
                                         :description => invoice.title
                                       })
      rescue Stripe::CardError => e
        self.last_error = e.message
        invoice.fail_payment!
        transaction.has_failed!
        return false
      end

      transaction.vendor_id = charge.id
      if !charge[:captured]
        # unknown as to whether this can ever be reached
        self.last_error = charge[:failure_message]
        invoice.fail_payment!
        transaction.has_failed!
        return false
      end

      transaction.succeed!
      invoice.mark_paid!
      true
    end
  end

  def update_payment_info(opts)
    if vendor_id.blank?
      _create_remote
    end

    card_param = nil
    if opts[:token].blank?
      card = card_from_opts(opts)
      return false if !card_valid?(card)
      card_param = {
        :number => card.number,
        :exp_month => card.month,
        :exp_year => card.year,
        :cvc => card.verification_value
      }
    else
      card_param = opts[:token]
    end

    _with_stripe_key do
      customer = Stripe::Customer.retrieve(self.vendor_id)
      customer.card = card_param

      begin
        customer.save
      rescue Stripe::CardError => e
        errors.add(:base, e.message)
        return false
      rescue Stripe::InvalidRequestError => e
        DetectedError.create!(:message => "Stripe profile update failure: #{e.message}.", :client_id => payment_gateway_profilable_id)
        errors.add(:base, I18n.t('payment_gateway_profile.update_error'))
        return false
      rescue => e
        DetectedError.create!(:message => "Very strange stripe profile exception thrown: #{e.message}.", :client_id => payment_gateway_profilable_id)
        errors.add(:base, I18n.t('payment_gateway_profile.update_error'))
        return false
      end

      _cache_customer(customer)
      save!
    end
  end

  RECOGNIZED_ERRORS = [
    "Failed to create"
  ]

  def update_plan!(plan_id)
    _with_stripe_key do
      customer = Stripe::Customer.retrieve(self.vendor_id)

      begin
        if customer.subscriptions.data.empty?
          result = customer.subscriptions.create(:trial_end => (Time.now + payment_gateway_profilable.class::TRIAL_DURATION).to_i,
                                                 :plan => plan_id)
        else
          sub = customer.subscriptions.data.first
          sub.plan = plan_id
          sub.trial_end = stripe_trial_ends_at.to_i if trialing?
          sub.save
        end
      rescue Stripe::InvalidRequestError => e
        if RECOGNIZED_ERRORS.any? { |m| e.message.start_with?(m) }
          payment_gateway_profilable.errors.add(:base, I18n.t('payment_gateway_profile.custom_plan_update_error', :message => e.message))
        else
          payment_gateway_profilable.errors.add(:base, I18n.t('payment_gateway_profile.plan_update_error'))
          DetectedError.create(:message => e.message, :business_id => self.payment_gateway_profilable.business_id)
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
