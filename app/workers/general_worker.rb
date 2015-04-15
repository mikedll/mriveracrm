class GeneralWorker
  extend ActiveModel::Naming

  attr_accessor :id, :invoked_method

  class << self
    def obj_enqueue(obj, invoked_method)
      o = new
      o.id = obj.id
      o.invoked_method = invoked_method
      Resque.push('general', o)
    end
  end

  def work
    obj_found.send(invoked_method) if !id.blank? && obj_found
  end

  # http://stackoverflow.com/questions/2481775/accessing-a-classs-containing-namespace-from-within-a-module
  def obj_found
    return @obj_found if @obj_found

    fully_qualified_name = self.class.to_s
    klass_container = fully_qualified_name.sub(Regexp.new("::#{fully_qualified_name.demodulize}$", ''))
    return nil if klass_container.blank?

    containing_klass = klass_container.constantize
    @obj_found ||= containing_klass.find_by_id id
  end

end
