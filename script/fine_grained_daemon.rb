#!/usr/bin/env ruby

gemfile = File.expand_path('../Gemfile', File.dirname(__FILE__))
begin
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.require(:fine_grained)
rescue Bundler::GemNotFound => e
  STDERR.puts e.message
  STDERR.puts "Try running `bundle install`."
  exit!
end


# This bundler group's configuration
SafeYAML::OPTIONS[:default_mode] = :safe

# This bundler group's environment configuration
ENV['RACK_ENV'] ||= "development"

# Fine Grained environment's app-specific loads
$LOAD_PATH << Bundler.root
require 'app/storage/fine_grained'

EM.run do
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EventMachine.start_server("127.0.0.1", 7803, FineGrained)
end

