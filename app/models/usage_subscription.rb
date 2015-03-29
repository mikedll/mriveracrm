class UsageSubscription < ActiveRecord::Base

  belongs_to :business
  has_one :payment_gateway_profile, as: :payment_gateway_profilable
  has_many :feature_selections
  has_many :features, :through => :feature_selections

  accepts_nested_attributes_for :feature_selections, :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :payment_gateway_profile, :reject_if => :all_blank

  validates :business_id, :presence => true

  after_create :require_payment_gateway_profile
  after_save :ensure_correct_plan!

  def reload(options = nil)
    @feature_prices = nil
    @calculated_plan_id = nil
    @calculated_price = nil
    super(options)
  end

  def renderable_json
    to_json({
              :methods => [:feature_selections_attributes, :payment_gateway_profile_attributes, :feature_prices, :price, :trial_ends_at, :remote_status, :current_period_ends_at],
              :include => {
                :payment_gateway_profile => {
                  :only => [:card_last_4, :card_brand],
                  :methods => [:card_prompt]
                }
              },
              :only => []
            })
  end

  def active_plan?
    payment_gateway_profile.active_plan?
  end

  def trial_ends_at
    payment_gateway_profile.stripe_trial_ends_at
  end

  def remote_status
    payment_gateway_profile.stripe_status
  end

  def current_period_ends_at
    payment_gateway_profile.stripe_current_period_ends_at
  end

  def trialing?
    payment_gateway_profile.trialing?
  end

  def price
    _calculate_price_and_plan
    @calculated_price
  end

  def feature_prices
    @feature_prices ||= Feature.bit_index_ordered.all.map do |feature|
      fp = feature.feature_pricings.for_generation(generation).price_ordered.first
      fp = feature.ensure_generation_pricing!(generation) if !fp
      {
        :id => feature.id,
        :price => fp.price
      }
    end
  end

  def feature_selections_attributes
    feature_selections.bit_index_ordered.map { |fs| { :id => fs.id, :feature_id => fs.feature_id } }
  end

  #
  # These attributes are fake.
  #
  def payment_gateway_profile_attributes
    PaymentGatewayProfile.card_virtual_attributes.inject({  }) { |acc, e| acc[e] = ""; acc }
  end

  def has_feature(f)
    features.include?(f)
  end

  def calculated_plan_id
    return @calculated_plan_id if @calculated_pland_id
    _calculate_price_and_plan
    @calculated_plan_id
  end

  def calculated_price
    return @calculated_price if @calculated_price
    _calculate_price_and_plan
    @calculated_price
  end

  def ensure_correct_plan!
    if payment_gateway_profile.stripe_plan != calculated_plan_id
      if !payment_gateway_profile.ensure_plan_created!(calculated_plan_id, calculated_price)
        DetectedError.create(:message => "Unable to create plan in stripe: #{calculated_plan_id}", :business_id => business_id)
        raise ActiveRecord::Rollback
      else
        if !payment_gateway_profile.update_plan!(calculated_plan_id, self)
          DetectedError.create(:message => "Unable to update plan in stripe: #{calculated_plan_id}", :business_id => business_id)
          raise ActiveRecord::Rollback
        else
          true
        end
      end
    else
      true
    end
  end

  def payment_gateway_profilable_remote_app_key
    key = MikedllCrm::Configuration.get('stripe.secret_key')
    if key.blank?
      raise "Stripe Secrete Key should never be blank. App is misconfigured."
    end
    key
  end

  def payment_gateway_profilable_subscribable?
    true
  end

  def payment_gateway_profilable_desc_attrs
    { :description => business.handle }
  end

  def payment_profile_profilable_card_args
    o = business.an_owner
    {
      :first_name => o.first_name,
      :last_name => o.last_name
    }
  end

  def require_payment_gateway_profile
    if payment_gateway_profile.nil?
      self.payment_gateway_profile = StripePaymentGatewayProfile.new(:payment_gateway_profilable => self)
      self.payment_gateway_profile.save!
    end
  end

  def notify_inactive!
    SubscriptionMailer.status_inactive(self).deliver!
  end

  def notify_signup!
    o = business.an_owner
    if o
      welcomed = business.lifecycle_notifications.by_identifier(LifecycleNotification::Common::WELCOME).first
      if !welcomed
        SubscriptionMailer.welcome(self).deliver!
        ln = business.lifecycle_notifications.build(:identifier => 'welcome')
        ln.save!
      end
    end
  end

  protected

  #
  # A given business may registered with a package that enables or
  # disables certain features, based on that business’ request. Billing
  # will assign to that business a monthly subscription that associates
  # costs with different features.

  # A business that doesn’t leverage a given feature may avoid the cost
  # of it.

  # A given MFE will be able to package certain feature sets by default,
  # thereby simplifying, or even hiding, the feature set from the end
  # user.  Stripe can associate a plan, with a plan code, that will
  # assign the subscription of the business a given monthly cost. As
  # that cost lapses, we can make decisions on how to dun the user’s
  # subscription...for example, we may disable all users for the
  # business for a period of time, like say, 1 year.

  # A challenge is that we will be adding and removing features
  # constantly. Each feature will have a cost, likely per user. How do
  # we bill for this?

  # We could simply roll monthly invoices, though that would leverage
  # none of Stripe’s recurrent billing, dunning, and bounced credit card
  # functionality.

  # If a given customer, Charlemagne, signs up for Clients and Products
  # basic features, and a later customer signs up for Portfolio, and we
  # want to charge $5/month per user for clients, and $10/month per user
  # for products, and $3/month per user for a portfolio...what are the
  # plan names? Doesn’t it seem like we want a bit string for this?
  # Especially if we have re-releases of features for different pricing?
  # Can we do that? For example, feature 1, generation 1? Where generation 1
  # end users retain the benefits of their pricing?

  # This should work, and provide very nice bit strings.

  # All that remains is to have a list of generations, each of which
  # supports a list of features. Earlier generations will have nulls for
  # feature slots that were never used.

  # Then, we have a list of features that take up slots in the bit
  # string, indicating true or false.

  # The generation part of the bit string should support a lot of
  # generations...If we released once a week for 20 years, we’d need 1040
  # values. In later generations, we can simply scrap old pricing and
  # raise pricing mechanisms...level the playing field and eliminate
  # certain generations.

  # Or even add to the bitstring. A generation a week for 100 years. That’s
  # 5,000. Or, 2^15 bits to pass that up. Let’s say 16 bits, then.

  # We also add 4 bits to cover 16 pricing schemes, this scheme just
  # being one of them, so that the same stripe key can be used for
  # customly-named plans that dont use this scheme (note that this may
  # result in a wasted first base-64 character in those plan's names,
  # or ids). This takes 4 bits.

  # That's 20 bits so far.

  # Let's then append 236 features, for 256 bits of information. Bits
  # representing features will be populated from the RHS of the
  # bitstring. This is evenly divisible by 64, for 44 base64 characters
  # that'll contribute to a plan id.

  # This makes 43 characters in the base-64 encoded string.
  # This is the Stripe ID of the plan, and the name can be simply “CRM
  # v24 32” with leading zeros.

  # This means we can look at a Stripe plan and calculate which
  # generation and set of features went into it.

  # Stripe provides meta data for features but that would entail making
  # names for plan and there doesn’t seem to be a point to that.  This
  # is, obviously, a departure from Gold/Bronze/Silver pricing. Bulk
  # discounts are not being provided here. Those can be handled via
  # coupons, or something. Or just not handled.

  # The bit string is thus:

  # [ 4 bits for pricing scheme | 16 bits for generation | 236 bits for features, starting at RHS ]

  # The resulting plan id will be 43 characters long...which is kind
  # of long but we'll see if it works.  it might not.

  # The cost of the plan can be determined from lookup tables in the
  # app.

  PRICING_SCHEME = 0
  GENERATION_BITS = 16
  FEATURE_BITS = 236

  def _calculate_price_and_plan
    price_and_bit_indices = features.inject({ :price => BigDecimal.new("0.0"), :bit_indices => {}}) do |acc, f|
      acc[:price] += feature_prices.select { |fp| fp[:id] == f.id }.first[:price]
      acc[:bit_indices][f.bit_index] = true
      acc
    end

    @calculated_price = price_and_bit_indices[:price]

    features_bitstring = ""
    (0...FEATURE_BITS).each do |i|
      if price_and_bit_indices[:bit_indices][i]
        features_bitstring = "1#{features_bitstring}"
      else
        features_bitstring = "0#{features_bitstring}"
      end
    end

    @calculated_plan_id = [[_to_bit_string(PRICING_SCHEME) + _to_bit_string(generation, 16) + features_bitstring].pack("B*")].pack("m0")
  end

  # converts integer to bit string, the length of which is a multiple of 4.
  # uses minimum length required.
  def _to_bit_string(i, min_width=0)
    hexed = i.to_s(16)
    padded = true if hexed.length % 2 == 1  # prepend 0
    bitstring = [(padded ? "0#{hexed}" : hexed)].pack("H*").unpack("B*").first
    bitstring = bitstring[4,bitstring.length - 4] if padded
    ("0" * [min_width - bitstring.length, 0].max) + bitstring
  end

end
