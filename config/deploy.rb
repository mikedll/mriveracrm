require "rvm/capistrano"
require "bundler/capistrano"
require 'capistrano-unicorn'

set :application, "mikedllcrm"
set :repository,  "git@github.com:mikedll/mriveracrm.git"

set :scm, :git
set :deploy_via, :remote_cache
set :branch, "master"
set :keep_releases, 10
set :user, "mrmike"

set :use_sudo, false
set :rvm_ruby_string, '2.0.0-p247@mikedllcrm'
set :rvm_type, :user

namespace :deploy do
  task :configs do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/credentials.yml #{release_path}/config/credentials.yml"
    run "ln -nfs #{shared_path}/sockets #{release_path}/tmp/sockets"
    run "ln -nfs #{shared_path}/pdfs #{release_path}/tmp/pdfs"
  end

  task :install_configs, :roles => [:web] do
    run "mkdir -p #{shared_path}/config"
    put File.read("config/credentials.yml.sample"), "#{shared_path}/config/credentials.yml"
  end

  def app_rvmsudo
    "export rvmsudo_secure_path=1; cd #{current_path};"
  end

  def dump_rvm_env
    "echo \"PATH=$PATH\" > tmp/path.env; echo \"GEM_HOME=$GEM_HOME\" >> tmp/path.env; echo \"GEM_PATH=$GEM_PATH\" >> tmp/path.env;"
  end

  task :prepare_foreman, :roles => [:app] do
    run "#{app_rvmsudo} #{dump_rvm_env} rvmsudo bundle exec foreman export upstart /etc/init -f config/foreman/Procfile.production -e config/foreman/production.env,tmp/path.env -u #{fetch(:user)} -a #{fetch(:application)} -l #{current_path}/log"
  end

  task :start, :roles => :app do
    run "sudo start #{fetch(:application)}"
  end

  task :stop, :roles => :app do
    run "sudo stop #{fetch(:application)}"
  end

  task :upstart_restart, :roles => :app, :except => { :no_release => true } do
    run "sudo stop #{fetch(:application)}; sudo start #{fetch(:application)}"
  end
end

task :rvminfo do
  run "rvm info"
end

task :production do
  role :web, "crmdev.mikedll.com"                          # Your HTTP server, Apache/etc
  role :app, "crmdev.mikedll.com"                          # This may be the same as your `Web` server
  role :db,  "crmdev.mikedll.com", :primary => true # This is where Rails migrations will run
  set :deploy_to, "/home/mrmike/mikedllcrm"
  set :rails_env, "production"
end

after 'deploy:update_code', 'deploy:configs'
after 'deploy:restart', 'deploy:upstart_restart'
