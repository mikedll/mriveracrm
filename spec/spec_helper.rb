require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  require 'webmock/rspec'
  require 'factory_girl'

  RSpec.configure do |config|
    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = false
    config.infer_base_class_for_anonymous_controllers = false
    config.order = "random"

    config.include Devise::TestHelpers, :type => :controller

    # config.filter_run_including :current => true
    config.filter_run_excluding :broken => true

    # Live api tests...
    config.filter_run_excluding :live_stripe => true
    config.filter_run_excluding :live_authorizenet => true

    LIVE_WEB_TESTS = [:live_stripe, :live_authorizenet]
    LIVE_WEB_TESTS.each do |filter|
      config.filter_run_excluding filter => true
    end

    # config.backtrace_clean_patterns = [
    #   # /\/lib\d*\/ruby\//,
    #   # /bin\//,
    #   #/gems/,
    #   # /spec\/spec_helper\.rb/,
    #   # /lib\/rspec\/(core|expectations|matchers|mocks)/
    # ]

    config.before(:all) do
      DatabaseCleaner.clean_with(:truncation)
      DatabaseCleaner.strategy = :transaction

      # Ensure no net connect, normally.
      WebMock.disable_net_connect! if LIVE_WEB_TESTS.all? { |live_filter| config.filter_run_excluding.any? { |k,v| k ==  live_filter } }
    end

    config.before(:suite) do
    end

    config.before(:each) do

      Business.current = nil
      RequestSettings.reset

      DatabaseCleaner.start

      # Global stubs.
      UsageSubscription.any_instance.stub(:require_payment_gateway_profile)
      UsageSubscription.any_instance.stub(:first_plan)
    end

    config.after(:each) do
      DatabaseCleaner.clean
    end


    # Cleanup carrierwave images
    config.after(:all) do
      if Rails.env.test? || Rails.env.cucumber?
        UsageSubscription.any_instance.stub(:require_payment_gateway_profile)
        UsageSubscription.any_instance.stub(:first_plan)
        tmp = FactoryGirl.create(:image)
        store_path = File.dirname(File.dirname(tmp.data.url))
        temp_path = tmp.data.cache_dir
        FileUtils.rm_rf(Dir["#{Rails.root}/public/#{store_path}/[^.]*"])
        FileUtils.rm_rf(Dir["#{Rails.root}/public/#{temp_path}/[^.]*"])
      end
    end
  end
end

Spork.each_run do

  ActiveSupport::Dependencies.clear # or classes don't reload...weird
  FactoryGirl.reload
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| load f}

end
