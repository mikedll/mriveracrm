

require 'active_support/concern'

module AttributesInFineGrained
  extend ActiveSupport::Concern

  class Attribute
    attr_accessor :fgc, :record, :name

    def initialize(options = {})
      options.reverse_merge!({ :fgc => FineGrainedClient.cli })
      self.fgc =  options[:fgc]
      self.name = options[:name]
      self.record = options[:record]
    end

    protected

    def _key
      @unique_name ||= "#{record.class.to_s.underscore}:#{record.id.to_i}:#{name}"
    end
  end

  class CounterAttribute < Attribute
    def incr
      fgc.incr(self._key)
    end

    def decr
      fgc.decr(self._key)
    end

    def to_i
      fgc.cread(self._key)
    end

    def ==(other)
      to_i == other
    end

    def <(other)
      to_i < other
    end

    def >(other)
      to_i > other
    end

    def !=(other)
      to_i != other
    end
  end

  included do
    attr_accessor :_attributes_in_fine_grained
  end

  module ClassMethods
    def counter(name)
      define_method("#{name}".to_sym) do
        self._attributes_in_fine_grained ||= {}
        self._attributes_in_fine_grained[name.to_sym] ||= CounterAttribute.new(:record => self, :name => name)
      end
    end
  end
end
