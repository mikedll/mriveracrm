# config/unicorn.rb

app_path = "/home/mrmike/mikedllcrm/current"

rails_env = ENV['RAILS_ENV'] || 'production'

worker_processes Integer(ENV["WEB_CONCURRENCY"] || 1)
timeout 15
preload_app false

listen "#{app_path}/tmp/sockets/unicorn.sock", :backlog => 64

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end 

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
