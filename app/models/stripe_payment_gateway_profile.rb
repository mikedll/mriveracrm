class StripePaymentGatewayProfile < PaymentGatewayProfile

  class NoStripeApiKey < Exception
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
  end

  def _with_stripe_key
    begin
      raise "Stripe api key was not blank. Probably a bug." if Stripe.api_key != ""

      Stripe.api_key = payment_gateway_profilable.payment_gateway_profilable_remote_app_key

      yield
    ensure
      Stripe.api_key = ""
    end
  end

end
