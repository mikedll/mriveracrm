class ApiStubs

  DEFAULT_VENDOR_ID = 'cus_5TT8ttHofQ6Ngt'

  @@customer_db = {}
  @@plan_db = {}

  def self.reset_bank!
    @customer_db = {}
    @plan_db = {}
  end

  def self.customer_db
    @customer_db ||= {}
  end

  def self.plan_db
    @plan_db ||= {}
  end


  def self.generic_stripe_stub!
    reset_bank!

    Stripe::Plan.stub(:retrieve) { |plan_id| ApiStubs.stripe_retrieve_or_create_plan(plan_id) }
    Stripe::Customer.stub(:create) { ApiStubs.stripe_create_customer(FactoryGirl.generate(:customer_vendor_id)) }
    Stripe::Customer.stub(:retrieve) do |cid|
      c = ApiStubs.stripe_retrieve_customer(cid)
      c.stub(:save) do
        with_card = ApiStubs.stripe_retrieve_customer_with_card(cid)
        if c.active_card.nil?
          c.active_card = with_card.active_card
        end

        with_card
      end
      c
    end
    Stripe::Charge.stub(:create) { |params| ApiStubs.stripe_charge(params[:amount]) }
  end

  def self.release_stripe_stub!
    Stripe::Plan.unstub(:retrieve)
    Stripe::Customer.unstub(:create)
    Stripe::Customer.unstub(:retrieve)
    Stripe::Charge.unstub(:create)
  end

  def self.authorize_net_create_customer_payment_profile(payment_profile_id = '12024206')
    YAML.load load('authorize_net_create_customer_payment_profile').result( binding )
  end

  def self.authorize_net_create_customer_profile(customer_profile_id = '13038989')
    YAML.load load('authorize_net_create_customer_profile').result( binding )
  end

  def self.stripe_retrieve_or_create_plan(plan_id = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=')
    return plan_db[plan_id] if plan_db[plan_id]

    created_at = Time.now
    plan_values = YAML.load load('stripe_live_plan').result( binding )
    plan_db[plan_id] = Stripe::Plan.construct_from(plan_values['values'], plan_values['api_key'])
  end

  def self.stripe_create_customer(customer_profile_id = DEFAULT_VENDOR_ID)
    created_at = Time.now

    subs = YAML.load load('subscriptions').result( binding )
    slo = Stripe::ListObject.construct_from(subs['values'], subs['api_key'])
    slo.stub(:create) do |opts|
      subscription_start = Time.now
      trial_end_timestamp = opts[:trial_end]

      sub = YAML.load load('stripe_live_subscription').result( binding )
      s = Stripe::Subscription.construct_from(sub['values'], sub['api_key'])

      s.plan = stripe_retrieve_or_create_plan
      s.stub(:plan=) do |plan_id|
        raise Stripe::InvalidRequestError.new("Unknown plan: #{plan_id}", plan_id) if plan_db[plan_id].nil?
        (s.instance_variable_get('@values'))[:plan] = plan_db[plan_id]
      end
      s.stub(:save)

      slo.data.push(s)
      nil
    end

    cards = YAML.load load('cards').result( binding )
    clo = Stripe::ListObject.construct_from(cards['values'], cards['api_key'])

    cus = YAML.load load('stripe_create_customer').result( binding )
    c = Stripe::Customer.construct_from(cus['values'], cus['api_key'])
    c.subscriptions = slo
    c.cards = clo

    customer_db[customer_profile_id] = c
    c
  end

  def self.stripe_retrieve_customer(customer_profile_id = DEFAULT_VENDOR_ID)
    return customer_db[customer_profile_id] if customer_db[customer_profile_id]

    created_at = Time.now

    sub = YAML.load load('stripe_customer_retrieve_subscriptions').result( binding )
    slo = Stripe::ListObject.construct_from(sub['values'], sub['api_key'])

    cards = YAML.load load('stripe_customer_retrieve_cards').result( binding )
    clo = Stripe::ListObject.construct_from(cards['values'], cards['api_key'])

    cus = YAML.load load('stripe_retrieve_customer').result( binding )
    c = Stripe::Customer.construct_from(cus['values'], cus['api_key'])
    c.subscriptions = slo
    c.cards = clo

    # not created...assume created awhile ago.
    customer_db[customer_profile_id] = c

    c
  end

  def self.stripe_retrieve_customer_with_card(customer_profile_id = DEFAULT_VENDOR_ID)
    c = stripe_retrieve_customer

    card_id = "card_7BtWFfF7g1zlZA"
    active_card_values = YAML.load load('stripe_customer_active_card').result( binding )
    active_card = Stripe::Card.construct_from(active_card_values['values'], active_card_values['api_key'])

    c.default_card = card_id
    c.default_source = card_id
    c.active_card = active_card
    customer_db[customer_profile_id] = c
  end

  def self.stripe_charge(amount = 7280)
    customer_profile_id = DEFAULT_VENDOR_ID

    vs = YAML.load load('stripe_charge').result( binding )
    charge = Stripe::Charge.construct_from(vs['values'], vs['api_key'])

    vs = YAML.load load('stripe_card_for_charge').result( binding )
    charge.card = Stripe::Card.construct_from(vs['values'], vs['api_key'])

    vs = YAML.load load('stripe_fee_details').result(binding)
    charge.fee_details = [Stripe::StripeObject.construct_from(vs['values'], vs['api_key'])]

    charge
  end


  def self.load(file)
    template = ERB.new( File.read( Rails.root.join('spec', 'api_stubs', "#{file}.yml.erb") ) )
  end

end
