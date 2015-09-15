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
gem 'activeadmin'
gem 'aws-ses', '~> 0.4.4', require: 'aws/ses'
gem 'cancan'
gem 'excon', '>= 0.27.5'
gem 'twitter-bootstrap-rails' # doesnt want to find twitter assets unless this is out here.
gem "nokogiri"
gem "rest-client"

gem "resque-web", :require => "resque_web", :github => "mikedll/resque-web", :branch => "resque-2"
# gem "resque-web", :require => "resque_web", :path => '../resque-web' # For dev mode

gem 'redis-objects'

group :default, :fine_grained do
  gem 'eventmachine'
  gem "safe_yaml"
end

group :default, :scheduler do
  gem 'resque', "~> 2.0.0.pre.1", github: "resque/resque"
  gem 'activemodel'
  gem 'activesupport'
  gem "clockwork"
  gem "safe_yaml"
end

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
  gem "foreman"
  gem "cknife"
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
