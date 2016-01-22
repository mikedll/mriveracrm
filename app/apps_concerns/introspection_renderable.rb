require 'active_support/concern'

module IntrospectionRenderable
  extend ActiveSupport::Concern

  included do
    def instance_variable_name_with_model_namespace_awareness
      return model_variable_name if model_variable_name
      instance_variable_name_without_model_namespace_awareness
    end

    def current_model_name_with_model_namespace_awareness
      return namespaced_model_klass_name.camelize if model_variable_name
      current_model_name_without_model_namespace_awareness
    end

    helper_method(:rendered_current_objects, :rendered_current_object)

    protected

    def configure_render(klass, opts = {})
      activate_default_apps
      apps_configuration[:primary_model] = klass if apps_configuration[:primary_model].nil?

      self.namespaced_model_klass_name = klass.to_s
      klass_name = namespaced_model_klass_name.demodulize
      namespaced_model_klass_name_underscored = namespaced_model_klass_name.underscore.tr('/', '_')
      controller_klass = self.class.to_s
      controller_klass_name = controller_klass.demodulize
      controller_name = controller_klass_name.gsub("Controller", '')
      controller_klass_container = controller_klass.gsub(Regexp.new("::#{controller_klass.demodulize}$"), '')

      if klass_name != namespaced_model_klass_name
        self.model_variable_name = namespaced_model_klass_name_underscored
        self.model_variable_name = namespaced_model_klass_name_underscored.pluralize if (controller_name.singularize != controller_name)
      end


      apps_configuration[:controller_klass_container] = controller_klass_container.underscore
      apps_configuration[:subject_klass_name] = (singular? ? klass_name : klass_name.pluralize).underscore
      apps_configuration.merge!({
          :app_top => (!plural_action? || singular?) ? false : true,
          :app_class => ((!plural_action? || singular?) ? namespaced_model_klass_name_underscored : namespaced_model_klass_name_underscored.pluralize).dasherize
        })

      apps_configuration[:title] = (((!plural_action? || singular?) ? klass_name : klass_name.pluralize).titleize) if apps_configuration[:title].nil?

      apps_configuration[:model_templates].push(klass)
      apps_configuration[:javascript_modules] += [controller_klass_container.underscore]
      apps_configuration[:view] = opts[:view] if opts[:view]
    end

    def activate_default_apps
      @apps_configuration = {
        :primary_model => nil,
        :subject_klass_name => '',
        :app_top => false,
        :app_class => '',
        :multiplicity => plural_action? ? 'plural' : 'single',
        :model_templates => [],
        :additional_templates => [],
        :additional_bootstraps => [],
        :resource_multiplicity => 'multiple',
        :javascript_modules => [],
        :view => nil
      }

      @apps_configuration[:title] = self.class.apps_klass_configuration[:title] if self.class.apps_klass_configuration[:title]
      @apps_configuration[:additional_templates] = self.class.apps_klass_configuration[:additional_templates]
      @apps_configuration[:additional_apps] = self.class.apps_klass_configuration[:additional_apps]

      self.class.apps_klass_configuration[:additional_bootstraps].each do |options|
        # This is a critical security point of our multi-tenant respect.
        results = if options[:has_defaults]
                    options[:klass].with_defaults(parent_object.send(options[:relation_name]))
                  else
                    parent_object.send(options[:relation_name])
                  end
        @apps_configuration[:additional_bootstraps].push(:app_class => options[:app_class], :bootstrap => results)
      end
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
      @json_config ||= apps_configuration[:primary_model].introspectable_configuration.serializable_configuration_for_view(apps_configuration[:view])
    end

  end

  module ClassMethods

    #
    # Add to make_resourceful builder api. This arguably could be
    # better-done by extending make_resourceful. But, apps
    # will probably eventually replace make_resourceful
    # on its own.
    #
    class MakeResourcefulDecorator
      def initialize(wrapped)
        @wrapped = wrapped
      end

      def title(s)
        self.controller.apps_klass_configuration[:title] = s
      end

      def include_templates(*t)
        self.controller.apps_klass_configuration[:additional_templates] += t
      end

      #
      # Expects a symbol as the model name which is the name of an association
      # on a parent object.
      #
      def include_bootstrap(model_name, options = {})
        options.reverse_merge!(
          :relation_name => model_name,
          :klass => model_name.to_s.singularize.camelize.constantize,
          :has_defaults => false,
          :app_class => model_name.to_s.dasherize
          )

        self.controller.apps_klass_configuration[:additional_bootstraps].push(options)
      end

      def include_app(name, app_config = {})
        model_name = name.to_s
        app_config.reverse_merge!(:multiplicity => "plural", :app_top => true, :disable_create => false, :back_button => true)
        app_config[:app_class] = (app_config[:multiplicity] == "plural" ? model_name.pluralize : model_name).dasherize if app_config[:app_class].nil?
        app_config[:model_name] = (app_config[:multiplicity] == "plural" ? model_name.pluralize : model_name) if app_config[:model_name].nil?
        app_config[:title] = app_config[:model_name].titleize if app_config[:title].nil?
        app_config[:app_name] = "#{app_config[:model_name].underscore}_app" if app_config[:app_name].nil?
        self.controller.apps_klass_configuration[:additional_apps].push(app_config)
      end

      def method_missing(method, *args, &block)
        @wrapped.send(method, *args, &block)
      end
    end

    def configure_apps(opts, &block)
      cattr_accessor :apps_primary_model, :apps_selected_view, :apps_klass_configuration

      attr_accessor :apps_configuration, :apps_model_inspector, :model_variable_name, :namespaced_model_klass_name

      before_filter :_check_for_primary_model

      self.apps_klass_configuration = { :additional_templates => [], :additional_apps => [], :additional_bootstraps => [] }
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

        MakeResourcefulDecorator.new(self).instance_eval(&block) if block
      end

      alias_method_chain :instance_variable_name, :model_namespace_awareness
      alias_method_chain :current_model_name, :model_namespace_awareness
    end
  end
end
