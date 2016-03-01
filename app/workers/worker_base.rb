class WorkerBase
  extend ActiveModel::Naming

  @@immediate_execution = false

  module Queues
    DEFAULT = :default
  end

  attr_accessor :id, :invoked_method, :invoked_method_arguments

  class << self
    def flag_immediate_execution!
      @@immediate_execution = true
    end

    def obj_enqueue(obj, invoked_method, *invoked_method_arguments)
      h = {
        :id => obj.id,
        :invoked_method => invoked_method,
        :invoked_method_arguments => invoked_method_arguments
      }

      if @@immediate_execution
        result = self.send(:perform, h)

        # this is a simulation of the application proceeding to work
        # with this object at a later point in time, possibly in a
        # different process. Any spec that exercises a backgrounded
        # method as if it is executed inline is a simulation of
        # a call to the method that creates the backgrounded
        # task to be executed later.
        obj.reload

        return result
      end

      FineGrainedClient.enqueue_to(Queues::DEFAULT, self, h)
    end
  end

  #
  # Resque is supposed to do this already but it doesn't.
  # development is apparently delayed on that front.
  #
  def self.perform(*args)
    job = new
    args.first.each {|k, v| job.instance_variable_set("@#{k}", v) }
    job.work
  end

  def work
    obj_found.send(invoked_method, *invoked_method_arguments) if !id.blank? && obj_found
  end

  # http://stackoverflow.com/questions/2481775/accessing-a-classs-containing-namespace-from-within-a-module
  def obj_found
    return @obj_found if @obj_found

    fully_qualified_name = self.class.to_s
    klass_container = fully_qualified_name.gsub(Regexp.new("::#{fully_qualified_name.demodulize}$"), '')
    return nil if klass_container.blank?

    containing_klass = klass_container.constantize
    @obj_found ||= containing_klass.find_by_id id
  end

end
