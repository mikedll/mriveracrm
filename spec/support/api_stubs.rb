class ApiStubs

  def self.authorize_net_create_customer_profile(customer_profile_id = '13038989')
    YAML.load load('authorize_net_create_customer_profile').result( binding )
  end

  def self.load(file)
    template = ERB.new( File.read( Rails.root.join('spec', 'spoofs', "#{file}.yml.erb") ) )
  end

end
