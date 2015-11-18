
require 'active_support/concern'

#
# Haven't found a use for this yet. Had planned on using
# it on a monitor. It's probably available for use later.
# Its implementation is good. mrivera 11/17/15
#
#
# Validation level starts at 1.
#
module ValidationTier
  extend ActiveSupport::Concern

  class OptionMergerWithIfCombine < ActiveSupport::OptionMerger
    private
      def method_missing(method, *arguments, &block)
        existing = @options[:if] if @options[:if]

        if arguments.last.is_a?(Proc)
          proc = arguments.pop
          arguments << lambda { |*args| @options.deep_merge(proc.call(*args)) }
        else
          arguments << (arguments.last.respond_to?(:to_hash) ? @options.deep_merge(arguments.pop) : @options.dup)
        end

        if existing
          arguments.last[:if] = (arguments.last[:if].nil? ? [] : [arguments.last[:if]]) if !arguments.last[:if].is_a?(Array)
          arguments.last[:if] << existing
        end

        @context.__send__(method, *arguments, &block)
      end
  end

  included do

    def reload
      self._validation_tier = 1
      super
    end

    protected

    cattr_accessor :_used_tiers
    attr_accessor :_validation_tier, :_required_validation_tier

    before_validation :_reset_validation_tier

    def _reset_validation_tier
      self._validation_tier = 1
    end

    def _increment_validation_tier_if_valid
      return if !errors.empty?
      self._validation_tier += 1
    end

    def _requires_validation_tier(n)
      _validation_tier >= n
    end
  end

  module ClassMethods
    def validation_tier(&block)
      self._used_tiers ||= 0
      self._used_tiers += 1
      _create_or_add_to_validation_tier(_used_tiers, &block)
    end

    # only purpose of this method is to bind a new value to n,
    # yielding a Proc with an incremented validation tier to check.
    def _create_or_add_to_validation_tier(n)
      yield OptionMergerWithIfCombine.new(self, :if => Proc.new { |r| r._requires_validation_tier(n) })
      validate { _increment_validation_tier_if_valid }
    end

  end
end
