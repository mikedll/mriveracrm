# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

namespace "log" do
  desc "Creates log directory if it doesn't exist"
  task :init do |t|
    path = File.expand_path( File.join(File.dirname(__FILE__), 'log') )
    FileUtils.mkdir path if not File.exists?( path )
  end
end
