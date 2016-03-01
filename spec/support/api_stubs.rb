class ApiStubs

  DEFAULT_VENDOR_ID = 'cus_5TT8ttHofQ6Ngt'
  DEFAULT_CARD_ID = 'card_7uTptFDpuiJxcr'

  @@customer_db = {}
  @@plan_db = {}
  @@source_db = {}

  def self.reset_bank!
    @customer_db = {}
    @plan_db = {}
    @source_db = {}
  end

  def self.customer_db
    @customer_db ||= {}
  end

  def self.plan_db
    @plan_db ||= {}
  end

  def self.source_db
    @source_db ||= {}
  end


  def self.generic_stripe_stub!
    reset_bank!

    Stripe::Plan.stub(:retrieve) { |plan_id| ApiStubs.stripe_retrieve_or_create_plan(plan_id) }
    Stripe::Customer.stub(:create) { ApiStubs.stripe_create_customer(FactoryGirl.generate(:customer_vendor_id)) }
    Stripe::Customer.stub(:retrieve) do |cid|
      c = ApiStubs.stripe_retrieve_customer(cid)
      c.stub(:save) do
        stripe_insert_card(c, c.card) if !c.card.nil?
        nil
      end
      c
    end
    Stripe::Charge.stub(:create) do |params|
      c = customer_db[params[:customer]]
      if c.active_card.last4 == "0341"
        raise Stripe::CardError.new("Your card was declined.", nil, nil)
      else
        ApiStubs.stripe_charge(c, params[:amount])
      end
    end
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

  def self.stripe_create_customer(customer_profile_id)
    created_at = Time.now

    cus = YAML.load load('stripe_create_customer').result( binding )
    c = Stripe::Customer.construct_from(cus['values'], cus['api_key'])

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
    c.subscriptions = slo

    stripe_customer_add_cards(c)

    c.stub(:delete) do
      customer_db.delete(c.id)
      c.deleted = true
      c
    end

    customer_db[customer_profile_id] = c
    c
  end

  def self.stripe_retrieve_customer(customer_profile_id)
    customer_db[customer_profile_id]
  end

  def self.stripe_retrieve_customer_with_card(customer_profile_id = DEFAULT_VENDOR_ID)
    c = stripe_retrieve_customer
    stripe_insert_card(c)
    customer_db[customer_profile_id] = c
  end

  def self.stripe_charge(customer, amount = 7280)
    customer_profile_id = customer.id
    card = customer.active_card
    card_last_4 = card.last4
    card_id = card.id

    charge = load_stripe_klass_with_binding('stripe_charge', Stripe::Charge, binding)
    charge.card = load_stripe_klass_with_binding('stripe_card', Stripe::Card, binding)
    charge.fee_details = [load_stripe_klass_with_binding('stripe_fee_details', Stripe::StripeObject, binding)]
    charge
  end

  def self.stripe_insert_card(c, card_params = nil)
    customer_profile_id = c.id
    card_id = "card_#{SecureRandom.hex(4)}"

    plast4 = (card_params[:number].nil? || card_params[:number].length < 4) ? nil : card_params[:number][card_params[:number].length - 4, 4]
    card_last_4 = plast4 || '4242'

    card = load_stripe_klass_with_binding('stripe_card', Stripe::Card, binding)

    c.default_card = card_id
    c.default_source = card_id
    c.active_card = card

    c.sources.data.push(card)
    source_db[card.id] = card

    c.sources.stub(:retrieve) do |source_id|
      s = source_db[source_id]

      s.stub(:delete) do
        c.sources.data.delete_if { |el| el.id == source_id }
        source_db.delete(source_id)
        s.deleted = true
        if c.active_card.id == source_id
          c.default_card = nil
          c.default_source = nil
          c.active_card = nil
        end
        s
      end

      s
    end
  end

  def self.stripe_customer_add_cards(c)
    customer_profile_id = c.id
    c.cards = load_stripe_klass_with_binding('cards', Stripe::ListObject, binding)
    c.sources = load_stripe_klass_with_binding('cards', Stripe::ListObject, binding)
  end

  def self.load_stripe_klass_with_binding(name, klass, b)
    yaml_values = YAML.load load(name).result( b )
    klass.construct_from(yaml_values['values'], yaml_values['api_key'])
  end

  def self.load(file)
    template = ERB.new( File.read( Rails.root.join('spec', 'api_stubs', "#{file}.yml.erb") ) )
  end

end
