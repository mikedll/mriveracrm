class SpecSupport

  class << self
    def valid_stripe_cc_params
      {
        :card_number => '4242424242424242',
        :expiration_month => '03',
        :expiration_year => '17',
        :cv_code => '111'
      }
    end
  end
end
