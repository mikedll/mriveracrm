require 'factory_girl'

FactoryGirl.define do

  factory :business do
    name "my small business"
    domain "www.domain" + SecureRandom.base64(8) + "yup.com"
    after(:create) do |business|
      Business.current = business
    end

    factory :emerging_papacy do
      name "Emerging Papacy"
      domain "www.emergingpapacy" + SecureRandom.base64(8) + "yup.com"
      after(:create) do |business, evaluator|
        FactoryGirl.create(:employee, :business => business, :first_name => "Gregory", :last_name => "the Great")
        FactoryGirl.create(:employee, :business => business, :first_name => "Saint", :last_name => "Benedict")
      end   
    end
  end

  factory :employee do
    business { FactoryGirl.create(:business) }
    first_name "Mike"
    last_name "Worker Bee"
    email { "employee" + SecureRandom.base64(8) + "@example.com" }
  end

  factory :credential do
    uid { SecureRandom.hex(12) }
    provider :someone
    name 'Bob Jenkins'
    email 'bob@email.com'

    factory :google_oauth2_credential do
      provider :google_oauth2
      oauth2_access_token { SecureRandom.hex(16) }
      oauth2_refresh_token { SecureRandom.hex(16) }
      oauth2_access_token_expires_at { Time.now + 3600 }
    end
  end

  factory :user do
    client { FactoryGirl.create(:stubbed_client) }
    first_name "Phil"
    last_name "Watson"
    email { "user" + SecureRandom.base64(8) + "@example.com" }
    after(:create) do |user|
      FactoryGirl.create(:google_oauth2_credential, :email => user.email, :user => user)
    end

    factory :client_user

    factory :employee_user do
      employee { FactoryGirl.create(:employee) }
      client nil
    end
  end

  factory :client do
    business { FactoryGirl.create(:business) }
    email { "user" + SecureRandom.base64(8) + "@example.com" }

    factory :stubbed_client do
      before(:create) { |profile, evaluator| PaymentGateway.stub(:authorizenet) { RSpec::Mocks::Mock.new("gateway", :create_customer_profile => ApiStubs.authorize_net_create_customer_profile) } }
    end
  end

  factory :invitation do
    before(:create) do |invitation|
      invitation.business = invitation.employee.try(:business) || invitation.client.business
    end

    factory :client_invitation, :parent => :invitation do
      client { FactoryGirl.create(:stubbed_client) }
    end

    factory :employee_invitation, :parent => :invitation do
      employee { FactoryGirl.create(:employee) }
    end

  end

  factory :authorize_net_payment_gateway_profile do
    client { FactoryGirl.create(:client) }

    factory :authorize_net_payment_gateway_profile_ready, :parent => :authorize_net_payment_gateway_profile do
      client { FactoryGirl.create(:client) }
      after(:create) do |profile, evaluator|
        profile.update_payment_info(:card_number => '4222222222222', :expiration_month => '08', :expiration_year => '2016', :cv_code => '111')
      end
    end
  end

  factory :stripe_payment_gateway_profile do
    client { FactoryGirl.create(:client) }
  end

  factory :invoice do
    description "Test invoice."
    client { FactoryGirl.create(:stubbed_client) }
    date { Time.now }
    total { 2500.00 }

    factory :unstubbed_client_invoice do
      client { FactoryGirl.create(:client) }
    end

    factory :pending_invoice do
      status "pending"
    end
  end

  factory :transaction do
    invoice { FactoryGirl.create(:invoice) }
  end

end
