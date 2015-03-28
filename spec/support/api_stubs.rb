class ApiStubs

  DEFAULT_VENDOR_ID = 'cus_5TT8ttHofQ6Ngt'

  @@maintained = {}

  def self.generic_stripe_stub!
    Stripe::Plan.stub(:retrieve).and_return(:some_plan)
    cnum = FactoryGirl.generate(:customer_vendor_id)
    Stripe::Customer.stub(:create) { ApiStubs.stripe_create_customer(cnum) }
    Stripe::Customer.stub(:retrieve) do
      c = ApiStubs.stripe_retrieve_customer(cnum)
      # subs_stub = RSpec::Mocks::Mock.new("subscriptions",
      #                                    {
      #                                      :data => RSpec::Mocks::Mock.new("data", :empty? => true),
      #                                      :create => nil
      #                                    })
      # c.stub(:subscriptions => subs_stub)
      c
    end
  end

  def self.release_stripe_stub!
    Stripe::Plan.unstub(:retrieve)
    Stripe::Customer.unstub(:create)
    Stripe::Customer.unstub(:retrieve)
  end

  def self.reset_bank
    @maintained = {}
  end

  def self.maintained
    @maintained ||= {}
  end

  def self.authorize_net_create_customer_payment_profile(payment_profile_id = '12024206')
    YAML.load load('authorize_net_create_customer_payment_profile').result( binding )
  end

  def self.authorize_net_create_customer_profile(customer_profile_id = '13038989')
    YAML.load load('authorize_net_create_customer_profile').result( binding )
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

      plan_name = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
      plan_values = YAML.load load('stripe_live_plan').result( binding )
      p = Stripe::Plan.construct_from(plan_values['values'], plan_values['api_key'])
      s.plan = p

      slo.data.push(s)
      nil
    end

    cards = YAML.load load('cards').result( binding )
    clo = Stripe::ListObject.construct_from(cards['values'], cards['api_key'])

    cus = YAML.load load('stripe_create_customer').result( binding )
    c = Stripe::Customer.construct_from(cus['values'], cus['api_key'])
    c.subscriptions = slo
    c.cards = clo

    maintained[customer_profile_id] = c
    c
  end

  def self.stripe_retrieve_customer(customer_profile_id = DEFAULT_VENDOR_ID)
    return maintained[customer_profile_id] if maintained[customer_profile_id]

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
    maintained[customer_profile_id] = c

    c
  end

  def self.stripe_charge(amount = 7280)
    customer_profile_id = DEFAULT_VENDOR_ID

    vs = YAML.load load('stripe_charge').result( binding )
    charge = Stripe::Charge.construct_from(vs['values'], vs['api_key'])

    vs = YAML.load load('stripe_card_for_charge').result( binding )
    charge.card = Stripe::Card.construct_from(vs['values'], vs['api_key'])

    vs = YAML.load load('stripe_fee_details').result(binding)
    charge.fee_details = Stripe::Object.construct_from(vs['values'], vs['api_key'])

    charge
  end


  def self.load(file)
    template = ERB.new( File.read( Rails.root.join('spec', 'api_stubs', "#{file}.yml.erb") ) )
  end

end
