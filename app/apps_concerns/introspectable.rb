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
    attr_accessor :model_name, :destroyable, :destroyable_enabler, :actions, :attributes, :nested_associations, :current_group, :views, :current_view

    def initialize(klass_name)
      self.model_name = klass_name
      self.destroyable = true
      self.destroyable_enabler = nil
      self.attributes = []
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

    def serializable_configuration_for_view(view = nil)
      attrs = attribute_stack_for_view(view).map do |attr_or_group|
        if attr_or_group.is_a?(Hash)
          attr_or_group.keys.first
        else
          # This assumes groups do not nest in each other.
          # We'd need recursion here if they did.
          attr_or_group.map { |attr| attr.keys.first }
        end
      end.flatten

      # It's up to the introspectable includer to except :id from
      # a given view or attributes set for json purposes. That
      # capability has not been coded as of 8/17/15.
      attrs.push(:id) if !attrs.include?(:id)

      methods = actions_for_view(view).map do |action_descriptor|
        action_descriptor.values.first.select { |k, v| [:enabler, :disabler].include?(k) }.map { |k, v| v }
      end.flatten

      {
        :only => attrs,
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
      (current_view.nil? ? attributes : current_view.last).push(current_group)
      self.current_group = nil
    end

    def view(name, opts = {}, &block)
      self.current_view = [name, { :attrs => [], :actions => [] }]
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
