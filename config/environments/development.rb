MikedllCrm::Application.configure do
  config.cache_classes = false
  config.whiny_nils = true

  config.consider_all_requests_local = true
  config.action_view.debug_rjs                         = true
  config.action_controller.perform_caching             = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  config.action_dispatch.best_standards_support = :builtin

  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  config.active_support.deprecation = :log

end
