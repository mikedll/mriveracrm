require 'active_support/concern'

#
#
# Allows things like the following in an ActiveRecord model:
#
# introspect do
#   can :destroy, :enabler => nil

#   attr :name
#   attr :hostname
#   attr :port
#   attr :active
#   group do
#     attr :last_result, :read_only
#     attr :last_polled_at, [:read_only, :datetime]
#   end
#   attr :last_error, [:read_only]

#   action :refresh, :type => :basic
#   action :rank, :label => "Run", :enabled_on => :runnable?, :confirm => I18n.t('backgrounded_polling.run_confirm')
# end
#
module Introspectable
  extend ActiveSupport::Concern

  class ViewNotFoundError < StandardError
  end

  class Configuration
    include ActionView::Helpers::TranslationHelper

    attr_accessor :model_name, :destroyable, :destroyable_enabler, :synthesized, :actions, :attributes, :nested_associations, :current_group, :views, :current_view

    def initialize(klass_name)
      self.model_name = klass_name
      self.destroyable = true
      self.destroyable_enabler = nil
      self.attributes = []
      self.synthesized = []
      self.actions = []
      self.nested_associations = []
      self.current_group = nil
      self.views = []
      self.current_view = nil
    end

    def nested_association(na)
      self.nested_associations.push(na)
    end

    def find_view(view = nil)
      v = views.select { |v| v.first == view }.first
      raise ViewNotFoundError("View #{view} does not exist on #{model_name}.") if v.nil?
      v.last
    end

    def attribute_stack_for_view(view = nil)
      if view
        find_view(view)[:attrs]
      else
        attributes
      end
    end

    def attr_name(attr)
      if attr.is_a?(Hash)
        attr.keys.first
      else
        attr
      end
    end

    def serializable_configuration_for_view(view = nil)
      attr_names = attribute_stack_for_view(view).map do |group|
        group.map { |attr| attr_name(attr) }
      end.flatten

      # It's up to the introspectable includer to except :id from
      # a given view or attributes set for json purposes. That
      # capability has not been coded as of 8/17/15.
      attr_names.push(:id) if !attr_names.include?(:id)

      methods = (actions_for_view(view).map do |action_descriptor|
        action_descriptor.values.first.select { |k, v| [:enabler, :disabler].include?(k) }.map { |k, v| v }
      end.flatten + synthesized_for_view(view)).uniq

      {
        :only => attr_names,
        :methods => methods
      }
    end

    def attr(a, traits = nil)
      t = traits ? { a => Array.wrap(traits) } : a
      stack = current_group ? current_group.last : (current_view ? current_view.last[:attrs] : attributes)
      stack.push(current_group ? t : [t])
    end

    def can(ability, options = {})
      case ability
      when :destroy
        self.destroyable = true
        self.destroyable_enabler = options[:enabler] if options[:enabler]
      else
      end
    end

    def synthesized_for_view(view = nil)
      if view
        find_view(view)[:synthesized]
      else
        synthesized
      end
    end

    def synth(synth_name)
      (current_view ? current_view.last[:synthesized] : synthesized).push(synth_name)
    end

    def actions_for_view(view = nil)
      if view
        find_view(view)[:actions]
      else
        actions
      end
    end

    # An action description looks like this:
    #
    #     :action_name => { :enabler => :some_predicate?, :type => :put_action }
    #
    # It's a hash with one key-value pair, where the value is a hash.
    #
    def action(a, traits)
      traits.reverse_merge!({ :type => :put_action })
      (current_view ? current_view.last[:actions] : actions).push({ a => traits })
    end

    def group(name = nil, &block)
      self.current_group = [name, []]
      instance_eval(&block)

      # We don't use name for now, until we make the group dsl keyword more interesting.
      (current_view.nil? ? attributes : current_view.last).push(current_group.last)
      self.current_group = nil
    end

    def view(name, opts = {}, &block)
      self.current_view = [name, { :attrs => [], :actions => [], :synthesized => [] }]
      instance_eval(&block)
      views.push(current_view)
      self.current_view = nil
    end
  end

  included do
    cattr_accessor :introspectable_configuration
    self.introspectable_configuration = Configuration.new(self.to_s)
  end

  module ClassMethods
    def introspect(options = {}, &block)
      introspectable_configuration.instance_eval(&block)
    end
  end
end
