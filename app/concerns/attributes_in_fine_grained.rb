
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

    def del
      fgc.del(key)
    end

    def key
      @unique_name ||= "#{record.class.to_s.underscore}:#{record.id.to_i}:#{name}"
    end

  end

  #
  # String value attribute.
  #
  class ValueAttribute < Attribute
    def set(s)
      (fgc.set(key, s) == "OK") ? s : nil
    end

    def to_s
      fgc.read(key)
    end
  end

  class CounterAttribute < Attribute
    def incr
      fgc.incr(key)
    end

    def decr
      fgc.decr(key)
    end

    def to_i
      fgc.cread(key)
    end

    def reset
      fgc.reset(key)
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
      fgc.sadd(key, s)
    end

    def <<(s)
      add(s)
    end

    def remove(s)
      fgc.srem(key, s)
    end

    def include?(s)
      vals = fgc.sread(key)
      vals.include?(s)
    end

    def reset
      fgc.sreset(key)
    end

    alias_method :clear, :reset
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

    #
    # This has issues, it appears, with IntrospectableRenderable's use of to_json.
    # It freezes the invoices retrieval for an employee. Calling to_s to side-step
    # this issue for now. M. Rivera 12/16/15.
    #
    def value(name)
      define_method(name.to_sym) do
        self._attributes_in_fine_grained ||= {}
        if self._attributes_in_fine_grained[name.to_sym].nil?
          self._attributes_in_fine_grained[name.to_sym] = ValueAttribute.new(:record => self, :name => name)
          self._attributes_in_fine_grained[name.to_sym].set("")
        end
        self._attributes_in_fine_grained[name.to_sym].to_s
      end

      define_method("#{name}=".to_sym) do |s|
        self._attributes_in_fine_grained ||= {}
        self._attributes_in_fine_grained[name.to_sym] ||= ValueAttribute.new(:record => self, :name => name)
        self._attributes_in_fine_grained[name.to_sym].set(s).to_s
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
