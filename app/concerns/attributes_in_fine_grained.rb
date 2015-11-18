
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

  #
  # String value attribute.
  #
  class ValueAttribute < Attribute
    def set(s)
      (fgc.set(_key, s) == "OK") ? s : nil
    end

    def to_s
      fgc.read(_key)
    end

    def ==(other)
      to_s == other
    end

    def <(other)
      to_s < other
    end

    def >(other)
      to_s > other
    end

    def !=(other)
      to_s != other
    end
  end

  class CounterAttribute < Attribute
    def incr
      fgc.incr(_key)
    end

    def decr
      fgc.decr(_key)
    end

    def to_i
      fgc.cread(_key)
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

  class SetAttribute < Attribute
    def add(s)
      fgc.sadd(_key, s)
    end

    def remove(s)
      fgc.srem(_key, s)
    end

    def include?(s)
      vals = fgc.sread(_key)
      vals.include?(s)
    end

    def reset
      fgc.sreset(_key)
    end
  end

  included do
    attr_accessor :_attributes_in_fine_grained
  end

  module ClassMethods
    def counter(name)
      define_method(name.to_sym) do
        self._attributes_in_fine_grained ||= {}
        self._attributes_in_fine_grained[name.to_sym] ||= CounterAttribute.new(:record => self, :name => name)
      end
    end

    def value(name)
      define_method(name.to_sym) do
        self._attributes_in_fine_grained ||= {}
        if self._attributes_in_fine_grained[name.to_sym].nil?
          self._attributes_in_fine_grained[name.to_sym] = ValueAttribute.new(:record => self, :name => name)
          self._attributes_in_fine_grained[name.to_sym].set("")
        end
        self._attributes_in_fine_grained[name.to_sym]
      end

      define_method("#{name}=".to_sym) do |s|
        self._attributes_in_fine_grained ||= {}
        self._attributes_in_fine_grained[name.to_sym] ||= ValueAttribute.new(:record => self, :name => name)
        self._attributes_in_fine_grained[name.to_sym].set(s)
      end
    end

    def set(name)
      define_method(name.to_sym) do
        self._attributes_in_fine_grained ||= {}
        self._attributes_in_fine_grained[name.to_sym] ||= SetAttribute.new(:record => self, :name => name)
      end
    end
  end
end
