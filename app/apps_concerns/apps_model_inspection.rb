require 'active_support/concern'

module AppsModelInspection
  extend ActiveSupport::Concern

  included do
    cattr_accessor :apps_primary_model
    attr_accessor :apps_configuration, :apps_model_inspector

    before_filter :_check_for_primary_model

    def configure_for_model(klass)
      activate_default_apps
      klass_name = klass.to_s
      controller_klass = self.class.to_s
      controller_klass_container = controller_klass.gsub(Regexp.new("::#{controller_klass.demodulize}$"), '')

      apps_configuration.merge!({
          :app_top => plural_action? ? true : false,
          :app_class => plural_action? ? klass_name.pluralize.underscore.dasherize : klass_name.singularize.underscore.dasherize,
          :title => klass.to_s.titleize
        })

      apps_configuration[:model_templates].push(klass)
      apps_configuration[:javascript_modules] += [controller_klass_container.split("::").map(&:underscore).join('/')]
    end

    def default_apps_configuration
      {
        :app_top => false,
        :app_class => '',
        :title => "Application",
        :multiplicity => plural_action? ? 'plural' : 'single',
        :model_templates => [],
        :resource_multiplicity => 'multiple',
        :javascript_modules => []
      }
    end

    def activate_default_apps
      @apps_configuration ||= default_apps_configuration
    end

    protected

    def _check_for_primary_model
      if self.class.apps_primary_model
        configure_for_model(self.class.apps_primary_model)
      end
    end
  end

  module ClassMethods
    def configure_apps(opts)
      self.apps_primary_model = opts[:model]
    end
  end
end
