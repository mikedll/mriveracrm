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

  class Configuration
    attr_accessor :destroyable, :destroyable_enabler, :actions, :attributes, :current_group

    def initialize
      self.destroyable = true
      self.destroyable_enabler = nil
      self.attributes = []
      self.actions = []
      self.current_group = nil
    end

    def attr(a, traits = nil)
      t = traits ? { a => Array.wrap(traits) } : a
      stack = current_group ? current_group.last : attributes
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

    def action(a, traits)
      traits.reverse_merge!({ :type => :put_action })
      actions.push({ a => traits })
    end

    def group(name = nil, &block)
      self.current_group = [name, []]
      instance_eval(&block)
      attributes.push(current_group.last)
      self.current_group = nil
    end

  end

  included do
    cattr_accessor :introspectable_configuration
    self.introspectable_configuration = Configuration.new
  end

  module ClassMethods
    def introspect(options = {}, &block)
      introspectable_configuration.instance_eval(&block)
    end
  end
end
