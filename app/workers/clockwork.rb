gemfile = File.expand_path('../../Gemfile', File.dirname(__FILE__))
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
SafeYAML::OPTIONS[:default_mode] = :safe


# Clockwork environment's configuration
ENV['RACK_ENV'] ||= "development"
Resque.redis = YAML.load_file(File.join(Bundler.root, "config", "resque.yml"))[ENV['RACK_ENV']]


# Clockwork environment's app-specific loads
$LOAD_PATH << Bundler.root
require 'app/workers/worker_base'
require 'app/workers/scheduled_event'

module Clockwork
  handler { |job| Resque.enqueue_to(WorkerBase::Queues::DEFAULT, 'ScheduledEvent', job) }
end
