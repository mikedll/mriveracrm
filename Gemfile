source 'http://rubygems.org'

# ruby '1.9.2'  # need to wait for cedar stack on heroku

gem 'rails', '3.0.3'

# vital
gem "rake", "~> 0.8.7"
gem "pg"
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

# for cap deploys
# unsure
gem 'activeadmin'



# probably leaving
gem 'sass'
gem 'compass'
gem "dynamic_form"

group :development do
  gem "barista"
  gem 'taps', '> 0.3.23'
  gem 'heroku_san'
  gem "heroku"
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
