require 'active_support/concern'

module AppsModelInspection
  extend ActiveSupport::Concern

  included do
    def instance_variable_name_with_model_namespace_awareness
      return model_variable_name if model_variable_name
      instance_variable_name_without_model_namespace_awareness
    end

    helper_method(:rendered_current_objects, :rendered_current_object)

    protected

    def configure_render(klass, opts = {})
      activate_default_apps
      apps_configuration[:primary_model] = klass if apps_configuration[:primary_model].nil?

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
      apps_configuration[:view] = opts[:view] if opts[:view]
    end

    def default_apps_configuration
      {
        :primary_model => nil,
        :subject_klass_name => '',
        :app_top => false,
        :app_class => '',
        :title => "Application",
        :multiplicity => plural_action? ? 'plural' : 'single',
        :model_templates => [],
        :resource_multiplicity => 'multiple',
        :javascript_modules => [],
        :view => nil
      }
    end

    def activate_default_apps
      @apps_configuration ||= default_apps_configuration
    end

    def _check_for_primary_model
      if self.class.apps_primary_model
        configure_render(self.class.apps_primary_model, :view => self.class.apps_selected_view)
      end
    end

    def with_update_and_transition(&block)
      if current_object.update_attributes(object_parameters)
        state_transition(&block)
      else
        response_for :update_fails
      end
    end

    def rendered_current_objects
      current_objects.to_json(json_config)
    end

    def rendered_current_object
      current_object.to_json(json_config)
    end

    def state_transition
      if yield
        response_for :update
      else
        response_for :update_fails
      end
    end

    private

    def json_config
      if apps_configuration[:view]
        apps_configuration[:primary_model].introspectable_configuration.serializable_configuration_for_view(apps_configuration[:view])
      else
        {}
      end
    end

  end

  module ClassMethods
    def configure_apps(opts, &block)
      cattr_accessor :apps_primary_model, :apps_selected_view

      attr_accessor :apps_configuration, :apps_model_inspector, :model_variable_name

      before_filter :_check_for_primary_model

      self.apps_primary_model = opts[:model]
      self.apps_selected_view = opts[:view] if opts[:view]

      make_resourceful do
        # Provide our own defaults.
        # We use rendered_current_object instead of make_resourceful's publish,
        # finding it too limited. We have some tricky scenarios I think where
        # we have to render an array of object to a string and hand it to
        # the view directly, which doesn't work well with make_resourceful's
        # publish. This can be revisited, though.

        response_for :new do
          render :layout => nil
        end

        response_for(:index) do |format|
          format.html do
            apps_configuration.merge!(:bootstrap => rendered_current_objects)
            render :template => "app_container"
          end
          format.json { render :json => rendered_current_objects }
        end

        response_for(:show) do |format|
          format.html do
            apps_configuration.merge!({
                :bootstrap => rendered_current_object,
            })
            render :template => "app_container"
          end
          format.json { render :json => rendered_current_object }
        end

        response_for(:update, :destroy) do |format|
          format.json { render :json => rendered_current_object }
        end

        response_for(:create) do |format|
          format.json { render :status => :created, :json => rendered_current_object }
        end

        response_for(:update_fails, :create_fails) do |format|
          format.json { render :status => :unprocessable_entity, :json => { :object => rendered_current_object, :errors => current_object.errors, :full_messages => current_object.errors.full_messages} }
        end
        self.instance_eval(&block) if block
      end

      alias_method_chain :instance_variable_name, :model_namespace_awareness
    end
  end
end
