require 'active_support/concern'

module AppsModelInspection
  extend ActiveSupport::Concern

  class ControllerModelModulesMismatch < StandardError
  end

  included do

    cattr_accessor :apps_primary_model
    attr_accessor :apps_configuration, :apps_model_inspector, :model_variable_name

    before_filter :_check_for_primary_model

    def configure_for_model(klass)
      activate_default_apps
      model_namespaced_klass_name = klass.to_s
      klass_name = model_namespaced_klass_name.demodulize
      model_namespaced_klass_name_underscored = model_namespaced_klass_name.underscore.tr('/', '_')
      controller_klass = self.class.to_s
      controller_klass_name = controller_klass.demodulize
      controller_name = controller_klass_name.gsub("Controller", '')
      controller_klass_container = controller_klass.gsub(Regexp.new("::#{controller_klass.demodulize}$"), '')

      if klass_name != model_namespaced_klass_name
        self.model_variable_name = model_namespaced_klass_name_underscored
        self.model_variable_name = model_namespaced_klass_name_underscored.pluralize if (controller_name.singularize != controller_name)
      end


      apps_configuration[:controller_klass_container] = controller_klass_container.underscore
      apps_configuration[:subject_klass_name] = (singular? ? klass_name : klass_name.pluralize).underscore
      apps_configuration.merge!({
          :app_top => singular? ? false : true,
          :app_class => (singular? ? model_namespaced_klass_name_underscored : model_namespaced_klass_name_underscored.pluralize).dasherize,
          :title => (singular? ? klass_name : klass_name.pluralize).titleize
        })

      apps_configuration[:model_templates].push(klass)
      apps_configuration[:javascript_modules] += [controller_klass_container.underscore]
    end

    def default_apps_configuration
      {
        :subject_klass_name => '',
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
      return model_variable_name if model_variable_name
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
