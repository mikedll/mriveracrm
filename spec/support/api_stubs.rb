class ApiStubs

  def self.authorize_net_create_customer_payment_profile(payment_profile_id = '12024206')
    YAML.load load('authorize_net_create_customer_payment_profile').result( binding )
  end

  def self.authorize_net_create_customer_profile(customer_profile_id = '13038989')
    YAML.load load('authorize_net_create_customer_profile').result( binding )
  end

  def self.stripe_create_customer(customer_profile_id = '')
    YAML.load load('stripe_create_customer').result( binding )
  end

  def self.load(file)
    template = ERB.new( File.read( Rails.root.join('spec', 'api_stubs', "#{file}.yml.erb") ) )
  end

end
