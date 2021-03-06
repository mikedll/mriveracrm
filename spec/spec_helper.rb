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
    config.filter_run_excluding :ignore => true

    #
    # Disable at least one of the following exclusion lines
    # to disable mocking of remote resources.
    #
    # You may both disable one of these exclusion filters
    # and add an inclusion of it to focus on the specs
    # that exercise remote resources and to which the aforementioned
    # filter applies.
    #
    GENERIC_WEB_TESTS = [:generic_web_test]
    LIVE_WEB_TESTS = [:live_stripe, :live_authorizenet]
    LIVE_WEB_TESTS.each do |filter|
      config.filter_run_excluding filter => true
      # config.filter_run_including filter => true
    end

    GENERIC_WEB_TESTS.each do |filter|
      config.filter_run_excluding filter => true
      # config.filter_run_including filter => true
    end

    might_be_running_live_test = !(LIVE_WEB_TESTS + GENERIC_WEB_TESTS).all? { |live_filter| config.filter_run_excluding.any? { |k,v| k == live_filter } }

    # config.backtrace_clean_patterns = [
    #   # /\/lib\d*\/ruby\//,
    #   # /bin\//,
    #   #/gems/,
    #   # /spec\/spec_helper\.rb/,
    #   # /lib\/rspec\/(core|expectations|matchers|mocks)/
    # ]

    config.before(:suite) do
      DatabaseCleaner.clean_with(:truncation)
      DatabaseCleaner.strategy = :transaction

      # Allow net connect if at least one live group is not excluded
      WebMock.disable! if might_be_running_live_test

      FineGrainedClient.flag_immediate_execution!

      FactoryGirl.create(:marketing_front_end)
    end

    config.before(:all) do
    end

    config.before(:each) do
      Business.current = nil
      RequestSettings.reset

      ApiStubs.generic_stripe_stub! if !might_be_running_live_test
      DatabaseCleaner.start
   end

    config.after(:each) do
      DatabaseCleaner.clean
    end


    # Cleanup persistent storage systems
    config.after(:suite) do
      if Rails.env.test? || Rails.env.cucumber?
        if :asdf.respond_to?(:stub)
          ApiStubs.generic_stripe_stub!

          tmp = FactoryGirl.create(:image)
          store_path = File.dirname(File.dirname(tmp.data.url))
          temp_path = tmp.data.cache_dir
          FileUtils.rm_rf(Dir["#{Rails.root}/public/#{store_path}/[^.]*"])
          FileUtils.rm_rf(Dir["#{Rails.root}/public/#{temp_path}/[^.]*"])

          ApiStubs.release_stripe_stub!
        end
        DatabaseCleaner.clean_with(:truncation)

        FineGrainedClient.cli.keys.each do |k|
          FineGrainedClient.cli.del(k)
        end
      end
    end
  end
end

Spork.each_run do

  ActiveSupport::Dependencies.clear # or classes don't reload...weird
  FactoryGirl.reload
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| load f}

end
