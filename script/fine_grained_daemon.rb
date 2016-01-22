#!/usr/bin/env ruby

gemfile = File.expand_path('../Gemfile', File.dirname(__FILE__))
begin
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.require(:fine_grained_daemon)
rescue Bundler::GemNotFound => e
  STDERR.puts e.message
  STDERR.puts "Try running `bundle install`."
  exit!
end


# This bundler group's includes and configuration
require 'active_support/core_ext'
SafeYAML::OPTIONS[:default_mode] = :safe

# This bundler group's environment configuration
ENV['RACK_ENV'] ||= "development"

# Fine Grained environment's app-specific loads
$LOAD_PATH << Bundler.root
require 'app/storage/fine_grained'
require 'app/storage/fine_grained_client'

EM.run do
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  FineGrained.ensure_opened(ARGV.length > 0 ? ARGV[0] : nil)
  EventMachine.start_server("localhost", FineGrained::PORT, FineGrained)
end

