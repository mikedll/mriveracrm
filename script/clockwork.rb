gemfile = File.expand_path('../Gemfile', File.dirname(__FILE__))
begin
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.require(:scheduler)
rescue Bundler::GemNotFound => e
  STDERR.puts e.message
  STDERR.puts "Try running `bundle install`."
  exit!
end

# Clockwork environment's includes
require 'multi_json'
require 'active_model'
require 'active_support/core_ext'
SafeYAML::OPTIONS[:default_mode] = :safe

# Clockwork environment's configuration
ENV['RACK_ENV'] ||= "development"

# Clockwork environment's app-specific loads
$LOAD_PATH << Bundler.root
require 'lib/app_configuration'
require 'app/workers/worker_base'
require 'app/workers/scheduled_event'
require 'app/storage/fine_grained'
require 'app/storage/fine_grained_client'


module Clockwork
  handler { |job| FineGrainedClient.enqueue_to(WorkerBase::Queues::DEFAULT, 'ScheduledEvent', job) }
  ScheduledEvent::Events.each do |period_and_task|
    every(period_and_task.first, period_and_task.last)
  end
end
