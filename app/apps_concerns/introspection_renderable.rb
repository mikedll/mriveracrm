require 'active_support/concern'

module IntrospectionRenderable
  extend ActiveSupport::Concern

  module SupplementaryMethods
    def instance_variable_name_with_model_namespace_awareness
      return model_variable_name if model_variable_name
      instance_variable_name_without_model_namespace_awareness
    end

    def current_model_name_with_model_namespace_awareness
      return namespaced_model_klass_name.camelize if model_variable_name
      current_model_name_without_model_namespace_awareness
    end

    def object_parameters
      params.slice(* apps_configuration[:primary_model].accessible_attributes.map { |k| k.underscore.to_sym } )
    end

    protected

    def configure_render(klass = nil, opts = {})
      @apps_configuration = {
        :primary_model => nil,
        :subject_klass_name => '',
        :app_top => false,
        :app_class => '',
        :multiplicity => plural_action? ? 'plural' : 'singular',
        :model_templates => [],
        :additional_templates => [],
        :additional_bootstraps => [],
        :controller_multiplicity => 'plural',
        :javascript_modules => [],
        :view => nil,
        :app_starter_params => {}
      }

      apps_configuration[:view] = opts[:view] if opts[:view]

      apps_configuration[:title] = self.class.apps_klass_configuration[:title] if self.class.apps_klass_configuration[:title]
      apps_configuration[:additional_templates] = self.class.apps_klass_configuration[:additional_templates]
      apps_configuration[:additional_apps] = self.class.apps_klass_configuration[:additional_apps]
      apps_configuration[:app_starter_params].merge!(self.class.apps_klass_configuration[:app_starter_params]) if !self.class.apps_klass_configuration[:app_starter_params].empty?
      apps_configuration[:plural_name_is_singular] = self.class.apps_klass_configuration[:plural_name_is_singular]

      apps_configuration[:disable_create] = self.class.apps_klass_configuration[:disable_create]

      self.class.apps_klass_configuration[:additional_bootstraps].each do |options|

        json_config = options[:klass].introspectable_configuration.serializable_configuration_for_view(apps_configuration[:view])
        # This is a critical security point of our multi-tenant respect.
        results = if options[:has_defaults]
                    options[:klass].with_defaults(parent_object.send(options[:relation_name]))
                  else
                    parent_object.send(options[:relation_name])
                  end.as_json(json_config)

        apps_configuration[:additional_bootstraps].push(:app_class => options[:app_class], :bootstrap => results)
      end

      apps_configuration[:model_templates] += self.class.apps_klass_configuration[:model_templates]

      controller_klass = self.class.to_s
      controller_klass_name = controller_klass.demodulize
      primary_model_name = controller_klass_name.gsub("Controller", '')
      controller_klass_container = controller_klass.gsub(Regexp.new("::#{controller_klass_name}$"), '')
      apps_configuration[:controller_multiplicity] = 'singular' if (primary_model_name.singularize == primary_model_name)
      primary_model_name = primary_model_name.singularize if apps_configuration[:controller_multiplicity] != 'singular' && !apps_configuration[:plural_name_is_singular]
      is_singular = (apps_configuration[:controller_multiplicity] == 'singular' || apps_configuration[:multiplicity] == 'singular')

      if klass
        apps_configuration[:primary_model] = klass
        self.namespaced_model_klass_name = klass.to_s
        namespaced_model_klass_name_underscored = namespaced_model_klass_name.underscore.tr('/', '_')
        primary_model_name = namespaced_model_klass_name_underscored.camelize
        if namespaced_model_klass_name != namespaced_model_klass_name.demodulize
          self.model_variable_name = apps_configuration[:controller_multiplicity] == 'plural' ? namespaced_model_klass_name_underscored.pluralize : namespaced_model_klass_name_underscored
        end

        apps_configuration[:model_templates].push(klass) if klass
      elsif apps_configuration[:plural_name_is_singular]
        self.model_variable_name = primary_model_name.underscore
      end

      apps_configuration[:primary_model_names] = {
        :instance_variable_name => instance_variable_name,
        :camelized_singular => primary_model_name,
        :camelized_plural => !apps_configuration[:plural_name_is_singular] ? primary_model_name.pluralize : primary_model_name,
        :dasherized => instance_variable_name.dasherize
      }

      apps_configuration[:controller_klass_container] = controller_klass_container.underscore
      apps_configuration[:subject_klass_name] = (is_singular ? primary_model_name : apps_configuration[:primary_model_names][:camelized_plural]).underscore
      apps_configuration.merge!({
          :app_top => is_singular ? false : true,
          :app_class => apps_configuration[:primary_model_names][:dasherized]
        })

      apps_configuration[:title] = ((is_singular ? primary_model_name : primary_model_name.pluralize).titleize) if apps_configuration[:title].nil?

      apps_configuration[:javascript_modules] += [controller_klass_container.underscore]
    end

    def _configure_render
      configure_render(self.class.apps_primary_model, :view => self.class.apps_selected_view)
    end

    def _indicate_primary_bootstrap_expected
      apps_configuration[:expecting_primary_bootstrap] = true
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
      @json_config ||= if apps_configuration[:primary_model]
                           apps_configuration[:primary_model].introspectable_configuration.serializable_configuration_for_view(apps_configuration[:view])
                       else
                         nil
                       end
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

      def include_model_template(*klasses)
        self.controller.apps_klass_configuration[:model_templates] += klasses
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
          :app_class => model_name.to_s.dasherize,
          :disable_create => true
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

      def app_starter_params(options)
        self.controller.apps_klass_configuration[:app_starter_params].merge!(options)
      end

      def actions(*available_actions)
        @wrapped.send(:actions, *available_actions)
        self.controller.apps_klass_configuration[:disable_create] = (available_actions.first != :all && !available_actions.include?(:create))
      end

      def regard_singular_name_as_plural
        self.controller.apps_klass_configuration[:plural_name_is_singular] = true
      end

      def method_missing(method, *args, &block)
        @wrapped.send(method, *args, &block)
      end
    end

    def configure_apps(opts = {}, &block)
      cattr_accessor :apps_primary_model, :apps_selected_view, :apps_klass_configuration

      attr_accessor :apps_configuration, :apps_model_inspector, :model_variable_name, :namespaced_model_klass_name

      before_filter :_configure_render
      before_filter :_indicate_primary_bootstrap_expected

      self.apps_klass_configuration = {
        :additional_templates => [],
        :additional_apps => [],
        :additional_bootstraps => [],
        :model_templates => [],
        :app_starter_params => {},
        :plural_name_is_singular => false
      }
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

      include SupplementaryMethods

      helper_method(:rendered_current_objects, :rendered_current_object)

      alias_method_chain :instance_variable_name, :model_namespace_awareness
      alias_method_chain :current_model_name, :model_namespace_awareness
    end
  end
end
