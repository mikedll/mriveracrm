MikedllCrm::Application.configure do

  config.cache_classes = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  config.serve_static_assets = false
  config.i18n.fallbacks = true

  config.active_support.deprecation = :notify

  config.action_mailer.default_url_options = { :host => 'www.mikedll.com:80' }

  config.action_controller.asset_host = 'd3dvas2xyyj1e3.cloudfront.net'

  config.assets.digest = true # why do I have to set this? I shouldn't have to.
  config.assets.compile = false
  config.assets.js_compressor = :yui
  config.assets.css_compressor = :yui
  config.assets.compress = true

  HOST = 'www.mikedll.com'

end
