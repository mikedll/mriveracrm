require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

require Bundler.root.join('config', 'version')

module Mikedll
  class Application < Rails::Application

    unless Rails.env.development?
      config.action_controller.asset_path = proc { |asset_path| 
        "/version_#{Mikedll::VERSION}#{asset_path}" 
      }
    end

    config.time_zone = "Pacific Time (US & Canada)"
  
  end
end
