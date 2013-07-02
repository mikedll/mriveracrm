source 'http://rubygems.org'

# ruby '1.9.2'  # need to wait for cedar stack on heroku

gem 'rails', '~> 3.2.0'

# vital
gem "rake", "~> 0.8.7"
gem "pg", '~> 0.11'
gem 'activerecord-postgresql-adapter'
gem "haml"
gem "haml-rails"
gem "aws-s3"
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

group :development do
  gem 'yui-compressor'
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem "right_aws"
  gem 'taps', '> 0.3.23'
  gem 'heroku_san'
  gem 'capistrano-unicorn', :require => false
  gem "capistrano"
  gem "rvm-capistrano"
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
end

group :production do
  gem 'unicorn'
end
