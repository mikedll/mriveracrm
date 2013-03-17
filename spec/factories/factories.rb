require 'factory_girl'

FactoryGirl.define do

  factory :business
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
end
