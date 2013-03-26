class StripePaymentGatewayProfile < PaymentGatewayProfile

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

    transaction = StripeTransaction.new(:payment_gateway_profile => self)
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


  def update_payment_info(opts)
    if opts[:token].blank?
      errors.add(:base, I18n.t('payment_gateway_profile.update_error'))
      return      
    end

    customer = Stripe::Customer.retrieve(self.vendor_id)
    customer.card = opts[:token]
    begin
      customer.save
    rescue Stripe::InvalidRequestError => e
      DetectedError.create!(:message => "Stripe profile update failure: #{e.message}.", :client_id => self.client.id)
      errors.add(:base, I18n.t('payment_gateway_profile.update_error'))
      return false
    rescue => e
      DetectedError.create!(:message => "Very strange stripe profile exception thrown: #{e.message}.", :client_id => self.client.id)
      errors.add(:base, I18n.t('payment_gateway_profile.update_error'))
      return false
    end

    _cache_customer(customer)
    save!
  end

  def reload_remote
    if self.vendor_id.blank?
      DetectedErrors.create(:message => "Reloading but no vendor id", :client_id => self.client.id)
      return
    end
    customer = Stripe::Customer.retrieve(self.vendor_id)
    _cache_customer(customer)
    save!
  end


  def _create_remote
    customer = Stripe::Customer.create(:description => client.id, :email => client.email)
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


end
