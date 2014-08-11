class AuthorizeNetPaymentGatewayProfile < PaymentGatewayProfile

  module AuthorizeResponses
    OK = 'Ok'
    ERROR = 'Error'
  end

  def public
    {
      :id => id,
      :card_prompt => card_prompt,
      :updated_at => updated_at
    }
  end

  def pay_invoice!(invoice)
    if self.vendor_id.nil? || self.card_profile_id.nil?
      self.last_error = I18n.t('payment_gateway_profile.cant_pay')
      return false 
    end

    if !invoice.can_pay?
      self.last_error = I18n.t('invoice.cannot_pay')
      return false
    end

    transaction = AuthorizeNetTransaction.new(:payment_gateway_profile => self)
    transaction.invoice = invoice
    transaction.amount = invoice.total
    transaction.begin!

    response = PaymentGateway.authorizenet.create_customer_profile_transaction ({
      :transaction => {
        :type => :auth_capture,
        :customer_profile_id => self.vendor_id,
        :customer_payment_profile_id => self.card_profile_id,
        :amount => transaction.amount
      }
    })

    transaction.vendor_id = response.params['direct_response']['transaction_id']
    transaction.authorizenet_gateway_response_code = response.params['direct_response']['response_code'].to_i
    transaction.authorizenet_gateway_response_reason_code = response.params['direct_response']['response_reason_code'].to_i

    if response.params['messages']['result_code'] != AuthorizeResponses::OK

      # known error response 
      if response.params['messages']['message']['code'] == 'E00027'

        # pretty errors that we can show to user
        if ([2,3,4,6,8,11,19,20,21,22,23,25,26,28,37,41,78,117,118,120,121,122,193,254,261] +
            (200..224).to_a +
            (315..319).to_a).include? transaction.authorizenet_gateway_response_reason_codegateway_response_reason_code

          transaction.error = "Payment failed. #{response.params['direct_response']['message']}"
          transaction.error.chop! if full_base_error.ends_with?('.')
          self.last_error = transaction.error
        else
          DetectedError.create!(:message => "Authorize.net payment gateway.pay_invoice! unexpected error. Message: #{response.params['direct_response']['message']}, Reason code: #{response.params['direct_response']['response_reason_code']}", :client_id => payment_gateway_profilable_id)
          transaction.error = I18n.t('errors.unexpected_internal_error')
        end
        
        invoice.fail_payment!
        transaction.has_failed!
        return false
      else
        # completey unexpected response from gateway
        DetectedError.create!(:message => "Authorize.net payment gateway.pay_invoice! very unexpected response: #{response.params}", :client_id => payment_gateway_profilable_id)
        transaction.error = I18n.t('errors.unexpected_internal_error')
        invoice.fail_payment!
        transaction.has_failed!
        return false
      end
    end

    # mark invoice as paid

    transaction.succeed!
    invoice.mark_paid!
    true
  end

  #
  # 
  #
  def update_payment_info(opts)
    card = card_from_opts(opts)

    return false if !card_valid?(card)

    call_opts = {
      :customer_profile_id => self.vendor_id,
      :payment_profile => {
        :payment => {
          :credit_card => card 
        }
      }
    }

    call_prefix = 'create'
    if !self.card_profile_id.nil?
      call_opts[:payment_profile].merge!(:customer_payment_profile_id => self.card_profile_id) 
      call_prefix = 'update'
    end

    response = nil
    begin
      response = PaymentGateway.authorizenet.send("#{call_prefix}_customer_payment_profile".to_sym, call_opts)
    rescue => e
      self.errors.add(:base, I18n.t('payment_gateway_profile.update_error'))
      return false      
    end
      
    if response.params['messages']['result_code'] != AuthorizeResponses::OK
      DetectedError.create!(:message => "Authorize.net payment profile update failure responded that duplicate customer payment profile already exists.", :client_id => payment_gateway_profilable_id) if response.params['messages']['message']['code'] == 'E00039'
      self.errors.add(:base, I18n.t('payment_gateway_profile.update_error'))
      return false
    end

    self.card_brand = card.brand.camelize
    self.card_last_4 = card.number.last(4)

    self.card_profile_id = response.params['customer_payment_profile_id'] if self.card_profile_id.nil?
    save!
  end

  def reload_remote
    if self.vendor_id.blank?
      DetectedError.create(:message => "Reloading but no vendor id", :client_id => payment_gateway_profilable_id)
      return
    end

    response = PaymentGateway.authorizenet.get_customer_profile :customer_profile_id => self.vendor_id

    if response.params['messages']['result_code'] != AuthorizeResponses::OK
      DetectedError.create!(:message => "Failed to retrieve customer profile #{response.params['messages']['message']}", :client_id => payment_gateway_profilable_id)
      return
    end
    
    if response.params['profile']['payment_profiles'] && response.params['profile']['payment_profiles']['customer_payment_profile_id']
      self.card_profile_id = response.params['profile']['payment_profiles']['customer_payment_profile_id']
      self.card_last_4 = response.params['profile']['payment_profiles']['payment']['credit_card']['card_number'].last(4)
    end

    self.save!
  end


  def _create_remote
    response = PaymentGateway.authorizenet.create_customer_profile(:profile => { :merchant_customer_id => payment_gateway_profilable_id })
    if response.params['messages']['result_code'] != AuthorizeResponses::OK
      if response.params['messages']['message']['code'] == 'E00039'
        DetectedError.create!(:message => "Tried to create customer profile when it already exists? Our vendor id was: #{self.vendor_id}", :client_id => payment_gateway_profilable_id)
        self.vendor_id = response.params['customer_profile_id']
        self.save!
        return
      end

      DetectedError.create!(:message => "Failed to create customer profile. Received message: #{response.params['messages']['message']}", :client_id => payment_gateway_profilable_id)
      return
    end

    self.vendor_id = response.params['customer_profile_id']
    self.save!
  end

end
