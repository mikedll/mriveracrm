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

  EventMachine.start_server("localhost", FineGrained::PORT, FineGrained)

  EM.defer lambda {
    fgc = FineGrainedClient.new
    fgc.close
  }

  # 40.times do
  #   EM.defer lambda {
  #     fgc = FineGrainedClient.new
  #     fgc.push("q1", "blueish2")
  #     fgc.push("q1", "redishtype")
  #     fgc.push("q1", "3")
  #   }
  # end

end

