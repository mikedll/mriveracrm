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

  class Credentials

    def self.config 
      @config ||= YAML.load( File.read( Rails.root.join('config', 'credentials.yml'))).with_indifferent_access
    end

    def self.get(path)
      cur = config
      path.to_s.split('.').each do |segment|
        cur = cur[segment.force_encoding('UTF-8').to_s]
      end
      cur      
    end
  end
 
  GOOGLE_OAUTH2_CLIENT_ID = Credentials.get('google.oauth2_client_id')
  GOOGLE_OAUTH2_CLIENT_SECRET = Credentials.get('google.oauth2_client_secret')

end
