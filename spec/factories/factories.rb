require 'factory_girl'

FactoryGirl.define do

  sequence(:random_name) { |n| "asdfas#{n}" } # #{Fake::Name.name}#{n}

  sequence(:settings_key) { |n| "key#{n}" }

  sequence(:feature_bit_index) { |n| Feature.count + n - 1 }

  sequence(:guest_email) { |n| "someone#{n}" + SecureRandom.base64(8) + "@example.com" }

  sequence(:employee_email) { |n| "employee#{n}" + SecureRandom.base64(8) + "@example.com" }

  sequence(:business_handle) { |n| "handle#{n}#{SecureRandom.hex(4)}yup" }

  factory :business do
    default_mfe { FactoryGirl.create(:marketing_front_end) }
    name "my small business"
    handle { generate(:business_handle) }
    host { "www.#{handle}.com" }

    google_oauth2_client_id "google_oauth2_client_idxxx"
    google_oauth2_client_secret "google_oauth2_client_secretxxx"

    stripe_secret_key "sk_test_SoDXR6QkygrYnlnFhDWKNbB2"
    stripe_publishable_key "pk_test_rPvMBvyuzsgRIXZFCW2xMmxz"

    after(:create) do |business, eval|
      if Business.current.nil? || RequestSettings.host.nil?
        Business.current = business
        RequestSettings.host = business.default_mfe.host
      end

      # Ensure owner exists.
      e = FactoryGirl.build(:employee, :business => business, :role => Employee::Roles::OWNER)
      FactoryGirl.create(:employee_user, :employee => e)
    end

    factory :emerging_papacy do
      name "Emerging Papacy"
      host { "www.emergingpapacy" + SecureRandom.base64(8) + "yup.com" }
      after(:create) do |business, evaluator|
        FactoryGirl.create(:employee, :business => business, :first_name => "Gregory", :last_name => "the Great")
        FactoryGirl.create(:employee, :business => business, :first_name => "Saint", :last_name => "Benedict")
      end
    end
  end

  factory :lifecycle_notification do
    business
  end

  factory :employee do
    business { FactoryGirl.create(:business) }
    first_name "Mike"
    last_name "Worker Bee"
    email { generate(:employee_email) }
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

  factory :user_base, :class => User do
    first_name "Phil"
    last_name "Watson"
    email { "user" + SecureRandom.base64(8) + "@example.com" }
    confirmed_at { Time.now }
    after(:create) do |user, evaluator|
      FactoryGirl.create(:google_oauth2_credential, :email => user.email, :user => user)
    end

    factory :user do
      client { FactoryGirl.create(:stubbed_client) }

      factory :client_user do
        business { client.business }
      end
    end

    factory :employee_user do
      employee { FactoryGirl.create(:employee) }
      business { employee.business }
      client nil

      factory :unconfirmed_new_employee_user do
        after :create do |user, evaluator|
          user.confirmed_at = nil
          user.send(:generate_confirmation_token!) # saves
        end
      end

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
        Stripe::Charge.stub(:create) { ApiStubs.stripe_charge }
      }
    end
  end

  factory :invitation do
    email { generate(:guest_email) }

    factory :client_invitation, :parent => :invitation do
      client { FactoryGirl.create(:stubbed_client) }
    end

    factory :employee_invitation, :parent => :invitation do
      employee { FactoryGirl.create(:employee) }
    end

    factory :new_business_invitation, :parent => :invitation do
      handle { generate(:business_handle) }
    end

  end

  factory :authorize_net_payment_gateway_profile do
    payment_gateway_profilable { FactoryGirl.create(:client) }

    factory :authorize_net_payment_gateway_profile_ready, :parent => :authorize_net_payment_gateway_profile do
      client { FactoryGirl.create(:client) }
      after(:create) do |profile, evaluator|
        profile.update_payment_info(:card_number => '4222222222222', :expiration_month => '08', :expiration_year => '2016', :cv_code => '111')
      end
    end
  end

  factory :stripe_payment_gateway_profile do
    payment_gateway_profilable { FactoryGirl.create(:client) }
  end

  factory :stripe_payment_gateway_profile_for_us, :class => StripePaymentGatewayProfile do

    # fancy dancing around after_create hooks
    before(:create) do |profile, evaluator|
      profile.stub(:_save_plan_on_profilable)
      profile.stub(:_create_remote)
    end

    after(:create) do |profile, evaluator|
      profile.payment_gateway_profilable = FactoryGirl.create(:usage_subscription, :payment_gateway_profile => profile)

      profile.unstub(:_save_plan_on_profilable)
      profile.unstub(:_create_remote)
      profile.send(:_save_plan_on_profilable)
      profile.send(:_create_remote)
    end
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

      factory :paid_invoice do
        after (:create) do |invoice, evaluator|
          FactoryGirl.create(:successul_outside_transaction, :invoice => invoice)
          invoice.mark_paid!
        end
      end
    end


  end

  factory :transaction do
    invoice { FactoryGirl.create(:pending_invoice) }

    factory :outside_transaction, :class => OutsideTransaction do
      outside_vendor { 'Paypal' }
      outside_id { '3434334' }

      factory :successul_outside_transaction do
        status "successful"
      end
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
    business
    name { "Widget " + SecureRandom.base64(3) }
    active { true }
  end

  factory :image do
    business
    data { File.new(Rails.root.join('spec', 'support', 'testphoto.jpg'), 'r') }
  end

  factory :marketing_front_end do
    host { "www.mfe#{SecureRandom.hex(4)}.com" }

    # Create some default features.
    after(:create) do |mfe, eval|
      if Feature.count == 0
        Feature.ensure_master_list_created!
      end
      mfe.features = Feature.all
    end
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

  factory :setting do
    key { generate(:settings_key) }
    value "good"
    value_type { "String" }
  end

  factory :usage_subscription_base, :class => UsageSubscription do
    business
    plan "98as7df98"
    remote_status "active"
    generation { 0 }

    # theoretically we should unstub the default plan stuff here...

    factory :usage_subscription do
      before(:create) { |us, evaluator|

        Stripe::Plan.stub(:retrieve).and_return(:some_plan)
        Stripe::Customer.stub(:create) { ApiStubs.stripe_create_customer}
        Stripe::Customer.stub(:retrieve) {
          c = ApiStubs.stripe_retrieve_customer
          subs_stub = RSpec::Mocks::Mock.new("subscriptions",
                                             {
                                               :data => RSpec::Mocks::Mock.new("data", :empty? => true),
                                               :create => nil
                                             })
          c.stub(:subscriptions => subs_stub)
          c
        }
      }

      after(:create) do |us, evaluator|
        # Compensate for spec_helper stubs.
        # require_payment_gateway_profile
        if us.payment_gateway_profile.nil?
          us.payment_gateway_profile = StripePaymentGatewayProfile.new(:payment_gateway_profilable => us)
          us.payment_gateway_profile.save!
        end

        # first_plan

        us.ensure_correct_plan!
      end
    end
  end

  factory :feature_base, :class => Feature do
    bit_index { generate(:feature_bit_index).to_i }
    name { generate(:random_name) }
    public_name { |r| r.name.titleize }

    factory :feature_no_pricing

    factory :feature do
      after(:create) do |f, eval|
        if !Feature::ALL.include?(f.name)
          # pricing will fail if we don't do it here.
          FactoryGirl.create(:feature_pricing, :feature => f)
        end
      end
    end
  end

  factory :feature_pricing do
    feature
    generation { 0 }
    price "9.99"
  end

  factory :feature_selection do
    feature
    usage_subscription
  end

  factory :feature_provision do
    feature
    marketing_front_end
  end

end
