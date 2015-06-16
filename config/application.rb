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
      #{Rails.root}/app/morality
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

  require 'app_configuration'

  GOOGLE_OAUTH2_CLIENT_ID = AppConfiguration.get('google.oauth2_client_id')
  GOOGLE_OAUTH2_CLIENT_SECRET = AppConfiguration.get('google.oauth2_client_secret')

  AUTHNET_LOGIN = AppConfiguration.get('authorizenet.api_login_id')
  AUTHNET_PASSWORD = AppConfiguration.get('authorizenet.transaction_key')
  AUTHNET_TEST = (AppConfiguration.get('authorizenet.test') == true)

end
