class ApiStubs

  DEFAULT_VENDOR_ID = 'cus_5TT8ttHofQ6Ngt'

  def self.authorize_net_create_customer_payment_profile(payment_profile_id = '12024206')
    YAML.load load('authorize_net_create_customer_payment_profile').result( binding )
  end

  def self.authorize_net_create_customer_profile(customer_profile_id = '13038989')
    YAML.load load('authorize_net_create_customer_profile').result( binding )
  end

  def self.stripe_create_customer(customer_profile_id = DEFAULT_VENDOR_ID)
    created_at = Time.now

    sub = YAML.load load('subscriptions').result( binding )
    slo = Stripe::ListObject.construct_from(sub['values'], sub['api_key'])

    cards = YAML.load load('cards').result( binding )
    clo = Stripe::ListObject.construct_from(cards['values'], cards['api_key'])

    cus = YAML.load load('stripe_create_customer').result( binding )
    c = Stripe::Customer.construct_from(cus['values'], cus['api_key'])
    c.subscriptions = slo
    c.cards = clo
    c
  end

  def self.stripe_retrieve_customer(customer_profile_id = DEFAULT_VENDOR_ID)
    created_at = Time.now

    sub = YAML.load load('stripe_customer_retrieve_subscriptions').result( binding )
    slo = Stripe::ListObject.construct_from(sub['values'], sub['api_key'])

    cards = YAML.load load('stripe_customer_retrieve_cards').result( binding )
    clo = Stripe::ListObject.construct_from(cards['values'], cards['api_key'])

    cus = YAML.load load('stripe_retrieve_customer').result( binding )
    c = Stripe::Customer.construct_from(cus['values'], cus['api_key'])
    c.subscriptions = slo
    c.cards = clo
    c
  end


  def self.load(file)
    template = ERB.new( File.read( Rails.root.join('spec', 'api_stubs', "#{file}.yml.erb") ) )
  end

end
