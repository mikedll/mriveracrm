require 'factory_girl'

FactoryGirl.define do

  factory :business do
    name "my small business"
    handle { "handle#{SecureRandom.hex(8)}yup" }
    domain { "www.#{handle}.com" }

    google_oauth2_client_id "google_oauth2_client_idxxx"
    google_oauth2_client_secret "google_oauth2_client_secretxxx"

    stripe_secret_key "sk_test_SoDXR6QkygrYnlnFhDWKNbB2"
    stripe_publishable_key "pk_test_rPvMBvyuzsgRIXZFCW2xMmxz"

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
    first_name "Phil"
    last_name "Watson"

    factory :stubbed_client do
      before(:create) { |profile, evaluator| 
        PaymentGateway.stub(:authorizenet) { RSpec::Mocks::Mock.new("gateway", :create_customer_profile => ApiStubs.authorize_net_create_customer_profile) } 

        Stripe::Customer.stub(:create) { ApiStubs.stripe_create_customer }
      }
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
    status { "open" }

    factory :unstubbed_client_invoice do
      client { FactoryGirl.create(:client) }
    end

    factory :pending_invoice do
      status { "pending" }
    end
  end

  factory :transaction do
    invoice { FactoryGirl.create(:pending_invoice) }

    factory :outside_transaction, :class => OutsideTransaction do
      outside_vendor { 'Paypal' }
      outside_id { '3434334' }
    end

    factory :authorize_net_transaction, :class => AuthorizeNetTransaction do
    end

    factory :stripe_transaction, :class => StripeTransaction do
      factory :paid_stripe_transaction do
        status { "successful" }
      end
    end
  end

  factory :product do
    business { FactoryGirl.create(:business) }
    name { "Widget " + SecureRandom.base64(3) }
    active { true }
  end

  factory :image do
    business { FactoryGirl.create(:business) }
    data { File.new(Rails.root.join('spec', 'support', 'testphoto.jpg'), 'r') }
  end

  factory :marketing_front_end do
    domain { "mfe#{SecureRandom.hex(8)}" }
  end

  factory :product_image do 
    ignore do
      seed_business { FactoryGirl.create(:business) }
    end

    active { false }
    primary { false }

    before(:create) do |record, evaluator|
      sb = if record.image
             record.image.business
           elsif record.product
             record.product.business
           else
             evaluator.seed_business
           end
      record.image = FactoryGirl.create(:image, :business => sb) if record.image.nil?
      record.product = FactoryGirl.create(:product, :business => sb) if record.product.nil?
    end
  end

end
