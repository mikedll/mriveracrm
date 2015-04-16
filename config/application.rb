require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module MikedllCrm
  class Application < Rails::Application

    config.autoload_paths += %W(
      #{Rails.root}/app/observers
      #{Rails.root}/app/uploaders
      #{Rails.root}/app/workers
      #{Rails.root}/app/apps_concerns
      #{Rails.root}/app/concerns
    )

    config.time_zone = "Pacific Time (US & Canada)"

    config.filter_parameters += [:password, :credit_card, :card_number]

    config.assets.enabled = true
    config.assets.precompile += ['application.js', 'application.css', 'home.css', 'home.js', 'client.js', 'manage.js', 'contact_page.js', 'gallery.js', 'public.js', 'public.css']

    config.generators do |g|
      g.template_engine :haml
      g.test_framework  :rspec, :fixture => false
      g.helper          false
      g.view_specs      false
      g.helper_specs    false
      g.stylesheets     false
      g.javascripts     false
    end

  end

  class Configuration

    def self.config
      return @config if @config
      @config = {
        # :google_oauth2_scope => 'userinfo.email,userinfo.profile,https://mail.google.com/mail/feed/atom,https://www.google.com/m8/feeds/'
        :google_oauth2_scope => 'userinfo.email,userinfo.profile'
      }
      config = if File.exists? Rails.root.join('config', 'credentials.yml')
                    YAML.load( File.read( Rails.root.join('config', 'credentials.yml'))).with_indifferent_access 
                 else
                   {}
                 end
      @config.merge!(config)
    end

    def self.get(path)
      cur = config
      path.to_s.split('.').each do |segment|
        cur = cur[segment.force_encoding('UTF-8').to_s] if cur
      end

      # retry, this time with env prefix.
      if cur.nil?
        cur = config[Rails.env]
        path.to_s.split('.').each do |segment|
          cur = cur[segment.force_encoding('UTF-8').to_s] if cur
        end
      end

      if cur.nil?
        cur = ENV[path]
      end

      cur
    end
  end
 
  GOOGLE_OAUTH2_CLIENT_ID = Configuration.get('google.oauth2_client_id')
  GOOGLE_OAUTH2_CLIENT_SECRET = Configuration.get('google.oauth2_client_secret')

  AUTHNET_LOGIN = Configuration.get('authorizenet.api_login_id')
  AUTHNET_PASSWORD = Configuration.get('authorizenet.transaction_key')
  AUTHNET_TEST = (Configuration.get('authorizenet.test') == true)

end
