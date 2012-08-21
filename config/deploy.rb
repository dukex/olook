load 'deploy/assets'
require 'airbrake/capistrano'
require 'capistrano/ext/multistage'
require 'bundler/capistrano'
#require 'new_relic/recipes'

set :stages, %w(prod1 prod2 prod3 prod4 prodspare prod_todos hmg dev resque showroom new_machine apptest prod_todas)

# app details
set :application, 'olook'
set :path_app, '/srv/olook/current'
set :deploy_to, '/srv/olook'
set :deploy_via, :remote_cache
 
# server details
set :user, 'root'
set :use_sudo, false
set :version_path, '/srv/olook/current'
set :bundle, '/usr/local/ruby/bin/bundle'
set :rake, '/usr/local/ruby/bin/rake'

set :path_log, '/mnt/debug'
# set :rails_env, "RAILS_ENV=production"
set :rails_env, "production"
set :env, 'production'

# repo details
set :scm, :git
set :repository, 'git@github.com:olook/olook.git'
set :git_enable_submodules, 1

default_run_options[:pty] = true
ssh_options[:port] = 13630
ssh_options[:forward_agent] = true

#after 'deploy:update', 'newrelic:notice_deployment'
after 'deploy', 'deploy:cleanup' # keep only the last 5 releases
