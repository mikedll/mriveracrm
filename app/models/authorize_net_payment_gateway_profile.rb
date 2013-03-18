class AuthorizeNetPaymentGatewayProfile < PaymentGatewayProfile

  module AuthorizeResponses
    OK = 'Ok'
    ERROR = 'Error'
  end

  # #
  # # Returns CustomerProfile with data from Authorize.net, including payment profile if it exists
  # #
  # def get_customer_profile!
  #   raise "Cannot get customer profile if id is blank. Internal code should check before calling this." if self.customer_profile_id.blank?
  #   response = PAYMENT_GATEWAY.get_customer_profile :customer_profile_id => self.customer_profile_id

  #   unless response.params['messages']['result_code'] == AuthorizeResponses::OK
  #     logger.error "Bad result code while getting customer profile #{response.params['messages']['result_code']} for account having id #{self.id}"
  #     return nil
  #   end

  #   self.customer_profile = CustomerProfile.new(self)
  #   if !response.params['profile']['payment_profiles'].nil? &&
  #      !response.params['profile']['payment_profiles']['customer_payment_profile_id'].blank?
  #     self.customer_profile.merge_attrs_from_webservice_response! response.params['profile']
  #   end
  #   self.customer_profile
  # end

  # #
  # # Completely sets up payment method with Authorize.Net. Returns true on success, false otherwise.
  # #
  # # Leave self.customer_profile up to date with params given.
  # #
  # # If customer doesn't exist, the customer will be created.
  # # If payment profile doesn't exist, it will be created.
  # # If payment profile already exists, it will be updated.
  # #
  # def update_or_create_customer_profile params
  #   self.create_customer_profile! if self.customer_profile_id.blank?

  #   get_customer_profile!
  #   raise "Expected get_customer_profile to never fail" if self.customer_profile.nil?
  #   self.customer_profile.merge_attrs! params

  #   return false if !self.customer_profile.valid?

  #   if !self.customer_profile.has_payment_profile?

  #     response = PAYMENT_GATEWAY.create_customer_payment_profile({
  #       :customer_profile_id => self.customer_profile_id, 
  #       :payment_profile => self.customer_profile.payment_profile_hash
  #     })
      
  #     if response.params['messages']['result_code'] == AuthorizeResponses::ERROR
  #       if response.params['messages']['message']['code'] == 'E00039'
  #         raise "Authorize.net responded that duplicate customer payment profile already exists. Internal code should have detected this."
  #       end

  #       self.customer_profile.errors[:base] = ERRORS_WHILE_SETTING_UP_PAYMENT_METHOD
  #       return false
  #     elsif response.params['messages']['result_code'] == AuthorizeResponses::OK
  #       # succeeded, move on
  #     else
  #       raise "Unexpected response from Authorize.net Web Service: #{response.params}"
  #     end
      
  #     get_customer_profile!
  #   else
  #     response = PAYMENT_GATEWAY.update_customer_payment_profile({
  #       :customer_profile_id => self.customer_profile_id,
  #       :payment_profile => self.customer_profile.payment_profile_hash.merge({
  #         :customer_payment_profile_id => self.customer_profile.customer_payment_profile_id
  #       })
  #     })

  #     if response.params['messages']['result_code'] == AuthorizeResponses::ERROR
  #       self.customer_profile.errors[:base] = ERRORS_WHILE_SETTING_UP_PAYMENT_METHOD
  #       return self.customer_profile
  #     elsif response.params['messages']['result_code'] == AuthorizeResponses::OK
  #       # succeeded, move on
  #     else
  #       raise "Unexpected response from Authorize.net Web Service"
  #     end

  #     get_customer_profile!
  #   end

  #   true
  # end

  # #
  # # This both hits the external service and finalizes the transaction values in the respective
  # # transaction.
  # #
  # # If we have a write error, the intended transaction should still be
  # # on disk.
  # #
  # def _resolve_at_gateway
  #   raise "Expected customer_profile to be cached on self before resolving with gateway" if self.customer_profile.nil?
  #   response = PAYMENT_GATEWAY.create_customer_profile_transaction ({
  #     :transaction => {
  #       :ref_id => self.intended_transaction.id,
  #       :type => :auth_capture,
  #       :customer_profile_id => self.customer_profile_id,
  #       :customer_payment_profile_id => self.customer_profile.customer_payment_profile_id,
  #       :amount => self.add_to_balance
  #     }
  #   })

  #   if response.params['messages']['result_code'] == AuthorizeResponses::OK
  #     self.balance += self.add_to_balance.to_f
  #     self.intended_transaction.remote_transaction_id = response.params['messages']['transaction_id']
  #     self.intended_transaction.balance_after = self.changes[:balance].last
  #     self.intended_transaction.gateway_response_code = response.params['direct_response']['response_code'].to_i
  #     self.intended_transaction.gateway_response_reason_code = response.params['direct_response']['response_reason_code'].to_i
  #     self.intended_transaction.settle
  #     self.add_to_balance = nil
  #   elsif response.params['messages']['message']['code'] == 'E00027'
  #     self.intended_transaction.remote_transaction_id = response.params['messages']['transaction_id']
  #     self.intended_transaction.balance_after = self.balance
  #     self.intended_transaction.gateway_response_code = response.params['direct_response']['response_code'].to_i
  #     self.intended_transaction.gateway_response_reason_code = response.params['direct_response']['response_reason_code'].to_i
  #     self.intended_transaction.fail_at_gateway

  #     if ([2,3,4,6,8,11,19,20,21,22,23,25,26,28,37,41,78,117,118,120,121,122,193,254,261] +
  #         (200..224).to_a +
  #         (315..319).to_a).include? self.intended_transaction.gateway_response_reason_code

  #       full_base_error = "Payment transaction failed. #{response.params['direct_response']['message']}"
  #       full_base_error.chop! if full_base_error.ends_with?('.')
  #       self.errors[:base] << full_base_error
  #       # this is basically a null-save. Nothing will actually happen, because no values
  #       # have changed. meanwhile, self.errors is populated.
  #     else
  #       msg = response.params['direct_response']['message']
  #       code = response.params['direct_response']['response_reason_code']
  #       raise "Unexpected reason code during transaction: #{code} with message #{msg}"
  #     end
  #   elsif
  #     self.intended_transaction.fail_at_gateway
  #     raise "Unexpected response from gateway: #{response.params}"
  #   end
  # end

  # #
  # # Assumes self.customer_profile is current, if it exists.
  # #
  # def _require_payment_profile
  #   return if (!self.customer_profile_id.blank? && !self.customer_profile.nil?)
  #   err = "A payment method is required for that action, but no payment method was found for your account"
  #   if self.customer_profile_id.blank?
  #     self.errors[:base] << err 
  #     return
  #   end

  #   get_customer_profile!
  #   if !self.customer_profile.has_payment_profile?
  #     self.errors[:base] << err
  #   end
  # end

  # def merge_attrs! attrs
  #   [:first_name, :last_name, :address, :city, :state, :zip, :country, :phone_number,
  #    :card_number, :expiration_year, :expiration_month, :card_code].each do |attr|
  #     self.instance_variable_set( "@#{attr.to_s}".to_sym, attrs[attr])
  #   end
  # end

  # def payment_profile_hash
  #   {
  #     :bill_to => {
  #       :first_name => self.first_name,
  #       :last_name => self.last_name,
  #       :address => self.address,
  #       :city => self.city,
  #       :state => self.state,
  #       :zip => self.zip,
  #       :country => self.country,
  #       :phone_number => self.phone_number
  #     },
  #     :payment => {
  #       :credit_card => ActiveMerchant::Billing::CreditCard.new({
  #         :first_name => self.first_name,
  #         :last_name => self.last_name,
  #         :month => self.expiration_month,
  #         :year => self.expiration_year,
  #         :number => self.card_number,
  #         :verification_value => self.card_code
  #       })
  #     }
  #   }
  # end

  # def assign_from_webservice_response(profile_params)

  #   if profile_params['merchant_customer_id'].to_i != self.account.id
  #     raise "Invalid state: merchant_customer_id (#{profile_params['merchant_customer_id']}) does not equal account_id (#{self.account.id}) of contained account" 
  #   end

  #   profile_params['payment_profiles']['bill_to'].tap do |params|
  #     self.first_name = params['first_name']
  #     self.last_name = params['last_name']
  #     self.address = params['address']
  #     self.city = params['city']
  #     self.state = params['state']
  #     self.zip = params['zip']
  #     self.country = params['country']
  #     self.phone_number = params['phone_number']
  #   end

  #   self.customer_payment_profile_id = profile_params['payment_profiles']['customer_payment_profile_id']

  #   profile_params['payment_profiles']['payment']['credit_card'].tap do |params|
  #     self.display_card_number = params['card_number']
  #     self.display_expiration_date = params['expiration_date']
  #   end

  #   nil
  # end

  def card_prompt
    card_last_4.blank? ? "No card on file" : "Card ending in #{card_last_4}"
  end

  #
  # 
  #
  def update_payment_info(opts)
    call_opts = {
      :customer_profile_id => self.vendor_id,
      :payment_profile => {
        :payment => {
          :credit_card => ActiveMerchant::Billing::CreditCard.new({
                                                                    :first_name => self.client.first_name,
                                                                    :last_name => self.client.last_name,
                                                                    :month => opts[:expiration_month].to_i,
                                                                    :year => opts[:expiration_year].to_i,
                                                                    :number => opts[:card_number],
                                                                    :verification_value => opts[:card_code]
                                                                  })

        }
      }
    }

    call_prefix = 'create'
    if !self.card_profile_id.nil?
      call_opts[:payment_profile].merge!(:customer_payment_profile_id => self.card_profile_id) 
      call_prefix = 'update'
    end
    response = PaymentGateway.authorizenet.send("#{call_prefix}_customer_payment_profile".to_sym, call_opts)
      
    if response.params['messages']['result_code'] != AuthorizeResponses::OK
      DetectedErrors.create!(:message => "Authorize.net payment profile update failure responded that duplicate customer payment profile already exists.", :client_id => self.client.id) if response.params['messages']['message']['code'] == 'E00039'
      self.errors.add(:base, I18n.t('payment_gateway_profile.update_error'))
      return false
    end

    self.card_last_4 = opts[:card_number].last(4)
    self.card_profile_id = response.params['customer_payment_profile_id'] if self.card_profile_id.nil?
    save!
  end

  def reload_remote
    if self.vendor_id.blank?
      DetectedErrors.create(:message => "Reloading but no vendor id", :client_id => self.client.id)
      return
    end

    response = PaymentGateway.authorizenet.get_customer_profile :customer_profile_id => self.vendor_id

    if response.params['messages']['result_code'] != AuthorizeResponses::OK
      DetectedErrors.create!(:message => "Failed to retrieve customer profile #{response.params['messages']['message']}", :client_id => self.client.id)
      return
    end
    
    if response.params['profile']['payment_profiles'] && response.params['profile']['payment_profiles']['customer_payment_profile_id']
      self.card_last_4 = response.params['profile']['payment_profiles']
    end

    self.save!
  end


  def _create_remote
    response = PaymentGateway.authorizenet.create_customer_profile(:profile => { :email => self.client.email })

    if response.params['messages']['result_code'] != AuthorizeResponses::OK
      if response.params['messages']['message']['code'] == 'E00039'
        DetectedError.create!(:message => "Tried to create customer profile when it already exists? Our vendor id was: #{self.vendor_id}", :client_id => self.client.id)
        self.vendor_id = response.params['customer_profile_id']
        self.save!
        return
      end

      DetectedError.create!(:message => "Failed to create customer profile. Received message: #{response.params['messages']['message']}", :client_id => self.client.id)
      return
    end

    self.vendor_id = response.params['customer_profile_id']
    self.save!
  end

end
