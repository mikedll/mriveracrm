class WorkerBase
  extend ActiveModel::Naming

  module Queues
    DEFAULT = :default
  end

  attr_accessor :id, :invoked_method, :args

  class << self
    def obj_enqueue(obj, invoked_method, *args)
      o = new
      o.id = obj.id
      o.invoked_method = invoked_method
      o.args = args
      Resque.enqueue_to(Queues::DEFAULT, o.class, o)
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
    obj_found.send(invoked_method, *args) if !id.blank? && obj_found
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
