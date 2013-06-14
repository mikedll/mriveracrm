require "rvm/capistrano"
require "bundler/capistrano"
require 'capistrano-unicorn'

set :application, "mikedllcrm"
set :repository,  "mrmike@ssh.mikedll.com:git/mikedll"

set :scm, :git
set :deploy_via, :remote_cache
set :branch, "develop"
set :keep_releases, 10
set :user, "mrmike"
set :scm_username, "mrmike"
set :use_sudo, false
set :rvm_ruby_string, '1.9.2@mikedllcrm'
set :rvm_type, :user

namespace :deploy do
  # task :start do ; end
  # task :stop do ; end
  # task :restart, :roles => :app, :except => { :no_release => true } do
  #   run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  # end

  task :configs do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/credentials.yml #{release_path}/config/credentials.yml"
    run "ln -nfs #{shared_path}/sockets #{release_path}/tmp/sockets"
  end
end

task :production do
  role :web, "crmdev.mikedll.com"                          # Your HTTP server, Apache/etc
  role :app, "crmdev.mikedll.com"                          # This may be the same as your `Web` server
  role :db,  "crmdev.mikedll.com", :primary => true # This is where Rails migrations will run
  set :deploy_to, "/home/mrmike/mikedllcrm"
  set :rails_env, "production"
end

after 'deploy:update_code', 'deploy:configs'
after 'deploy:restart', 'unicorn:restart'  # app preloaded
