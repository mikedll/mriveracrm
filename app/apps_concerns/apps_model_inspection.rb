require 'active_support/concern'

module AppsModelInspection
  extend ActiveSupport::Concern

  class ControllerModelModulesMismatch < StandardError
  end

  included do

    cattr_accessor :apps_primary_model
    attr_accessor :apps_configuration, :apps_model_inspector, :model_namespace_aware_name

    before_filter :_check_for_primary_model

    def configure_for_model(klass)
      activate_default_apps
      model_namespaced_klass_name = klass.to_s
      klass_name = model_namespaced_klass_name.demodulize
      controller_klass = self.class.to_s
      controller_klass_container = controller_klass.gsub(Regexp.new("::#{controller_klass.demodulize}$"), '')

      # assert overlap between controller and model modules, as an
      # integrity check.

      if klass_name != model_namespaced_klass_name
        self.model_namespace_aware_name = (plural_action? ? model_namespaced_klass_name.pluralize : model_namespaced_klass_name).underscore.tr("/", "_")
      end

      apps_configuration.merge!({
          :app_top => plural_action? ? true : false,
          :app_class => plural_action? ? klass_name.pluralize.underscore.dasherize : klass_name.singularize.underscore.dasherize,
          :title => klass_name.titleize
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

    def instance_variable_name_with_model_namespace_awareness
      return model_namespace_aware_name if model_namespace_aware_name
      instance_variable_name
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
      alias_method_chain :instance_variable_name, :model_namespace_awareness
    end
  end
end
