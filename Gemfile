source 'http://rubygems.org'

ruby '2.0.0'

gem 'rails', '~> 3.2.0'

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
gem "fog"
gem 'rmagick'
gem 'jquery-rails', '~> 2.1'
gem 'stripe'
gem 'rest-client'
gem 'activeadmin'
gem 'aws-ses', '~> 0.4.4', require: 'aws/ses'
gem 'cancan'
gem 'excon', '>= 0.27.5'
gem 'twitter-bootstrap-rails' # doesnt want to find twitter assets unless this is out here.
gem "nokogiri"
gem "rest_client"

group :assets do
  gem 'yui-compressor'
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

group :development do
  gem "right_aws"
  gem 'taps', '> 0.3.23'
  gem 'capistrano-unicorn', :require => false
  gem "capistrano"
  gem "rvm-capistrano", :require => false
  gem "rvm"
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
