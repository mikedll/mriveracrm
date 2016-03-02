source 'http://rubygems.org'

ruby '2.0.0'

gem 'rails', '~> 4.0'
gem 'activesupport', :group => [:default, :scheduler]


# vital
gem "rake", ">= 10.0.0"
gem "pg", '~> 0.11'
gem 'activerecord-postgresql-adapter'
gem "haml"
gem "haml-rails"
gem "aws-s3", '>= 0.6.3'
gem "simple_form"
gem 'state_machine'
gem 'devise'
gem 'omniauth'
gem "omniauth-google-oauth2"
gem 'make_resourceful'
gem "activemerchant", '~> 1.31'
gem 'carrierwave'
# gem "fog"
gem 'rmagick'
gem 'jquery-rails'
gem 'stripe'
gem 'activeadmin', '~> 1.0.0.pre2' # mit
gem 'aws-ses', '~> 0.4.4', require: 'aws/ses'
gem 'cancan'
gem 'excon', '>= 0.27.5'
gem 'twitter-bootstrap-rails' # doesnt want to find twitter assets unless this is out here.
gem "nokogiri"
gem "rest-client"
gem "foreman"
gem 'kramdown' # mit

gem "safe_yaml", :group => [:default, :scheduler]
gem 'multi_json'

gem 'finegrained', :github => 'mikedll/finegrained'
# gem 'finegrained', :path => '../finegrained'

group :default, :scheduler do
  gem 'activemodel'
  gem "clockwork"
end

group :assets do
  gem 'yui-compressor'
end

group :development do
  gem "right_aws"
  gem 'capistrano-unicorn', :require => false
  gem "capistrano"
  gem "rvm-capistrano", :require => false
  gem "rvm"
  gem "cknife", :github => 'mikedll/cknife'
  # gem "cknife", :path => '../cknife'
end

group :test, :development do
  gem 'rb-inotify'
  gem "guard-spork"
  gem "guard-rspec"
  gem "timecop"
  gem "database_cleaner"
  gem 'rspec-rails'
  gem "capybara"
  gem "factory_girl_rails"
  gem "faker"
end

group :test do
  gem 'webmock'
end

group :production do
  gem 'unicorn'
end
