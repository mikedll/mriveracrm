class SpecSupport

  class << self
    def without_feature(user, feature_name)
      f = Feature.find_by_name feature_name
      user.employee.business.usage_subscription.features.delete(f)
    end

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
