require 'factory_girl'

FactoryGirl.define do

  factory :user do
    email { "user" + SecureRandom.base64(8) + "@example.com" }
  end
end
