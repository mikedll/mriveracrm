require 'factory_girl'

FactoryGirl.define do

  factory :business do
    domain "www.domain" + SecureRandom.base64(8) + "yup.com"
  end
  factory :credential

  factory :user do
    email { "user" + SecureRandom.base64(8) + "@example.com" }
    after(:create) do |user, evaluator|
      FactoryGirl.create(:credential, :email => user.email)
    end
  end

  factory :client do
    email { "user" + SecureRandom.base64(8) + "@example.com" }
  end

  factory :invitation

  factory :client_invitation, :parent => :invitation do
    client { FactoryGirl.create(:client) }
  end

  factory :authorize_net_payment_gateway_profile do
    client { FactoryGirl.create(:client) }
  end

  factory :authorize_net_payment_gateway_profile_ready, :parent => :authorize_net_payment_gateway_profile do
    client { FactoryGirl.create(:client) }
    after(:create) do |profile, evaluator|
      profile.update_payment_info(:card_number => '4222222222222', :expiration_month => '08', :expiration_year => '2016', :card_code => '111')
    end
  end

  factory :stubbed_authorize_net_payment_gateway_profile, :parent => :authorize_net_payment_gateway_profile do
    before(:create) do |profile, evaluator|
      PaymentGateway.stub(:authorizenet) { RSpec::Mocks::Mock.new("gateway", :create_customer_profile => ApiStubs.authorize_net_create_customer_profile) }
    end
    client { FactoryGirl.create(:client) }
  end

  factory :invoice do
    description "Test invoice."
    client { FactoryGirl.create(:client) }
    date { Time.now }
    total 2500.00
  end

  factory :transaction do
    invoice { FactoryGirl.create(:invoice) }
  end

end
