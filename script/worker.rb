#!/usr/bin/env ruby

require File.expand_path('../config/boot', File.dirname(__FILE__))
require 'multi_json'

c = FineGrainedClient.new
while 1
  s = c.shift(WorkerBase::Queues::DEFAULT)
  if s
    j = MultiJson.decode(s)
    klass = j['klass']
    klass.constantize.send(:perform, j['args'])
  end
end
