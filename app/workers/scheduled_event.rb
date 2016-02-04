class ScheduledEvent

  # we don't have inflections defined in railsless clockwork
  # environment, so use camelcase class name.
  Events = [
    [1.minute, 'IT::MonitoredComputer.detect_missing!'],
    [1.day, 'Business.expire_payment_information_when_dormant!']
  ]

  def self.perform(event)
    klass_name, klass_method_name = event.split('.')

    begin
      klass = klass_name.constantize
      klass.send(klass_method_name)
    rescue => e
      # not sure how to handle it, for now
      raise
    end
  end
end
