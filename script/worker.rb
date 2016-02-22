#!/usr/bin/env ruby

require ::File.expand_path('../../config/environment',  __FILE__)

require 'fine_grained_client'

c = FineGrainedClient.new
while 1
  s = c.shift(WorkerBase::Queues::DEFAULT)
  if s
    j = MultiJson.decode(s)
    klass = j['klass']
    klass.constantize.send(:perform, *j['args'])
  end
end
