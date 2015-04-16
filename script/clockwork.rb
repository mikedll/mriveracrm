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

# Clockwork environment's initializing setup
Resque.redis = AppConfiguration.get('redis')


module Clockwork
  handler { |job| Resque.enqueue_to(WorkerBase::Queues::DEFAULT, 'ScheduledEvent', job) }
  every(1.hour, ScheduledEvent::Events::RESET_SEO_RANKERS)
  every(1.hour, ScheduledEvent::Events::RUN_SEO_RANKERS)
end
