role :app, 'apptest.olook.com.br'
role :web, 'apptest.olook.com.br'
role :db, 'apptest.olook.com.br'

# repo details
set :branch, fetch(:branch, 'master')
set :rails_env, 'staging'

# tasks
namespace :deploy do
  task :default, :role => :app do
    #configuring_server
    update #capistrano internal default task
    yml_links
    rake_tasks
    restart
  end

  desc 'Seting Up'
  task :configuring_server, :roles => :web do
    run "mkdir /srv/olook/#{branch}"
    set :path_app, "/srv/olook/#{branch}"
    setup
    cold
  end

  desc 'Create symlinks'
  task :yml_links, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/database.yml #{version_path}/config/database.yml"
    run "ln -nfs #{deploy_to}/shared/analytics.yml #{version_path}/config/analytics.yml"
    run "ln -nfs #{deploy_to}/shared/aws.yml #{version_path}/config/aws.yml"
    run "ln -nfs #{deploy_to}/shared/criteo.yml #{version_path}/config/criteo.yml"
    run "ln -nfs #{deploy_to}/shared/fog_credentials.yml #{version_path}/config/fog_credentials.yml"
    run "ln -nfs #{deploy_to}/shared/moip.yml #{version_path}/config/moip.yml"
    run "ln -nfs #{deploy_to}/shared/newrelic.yml #{version_path}/config/newrelic.yml"
    run "ln -nfs #{deploy_to}/shared/promotions.yml #{version_path}/config/promotions.yml"
    run "ln -nfs #{deploy_to}/shared/resque.yml #{version_path}/config/resque.yml"
    run "ln -nfs #{deploy_to}/shared/yahoo.yml #{version_path}/config/yahoo.yml"
    run "ln -nfs #{deploy_to}/shared/facebook.yml #{version_path}/config/facebook.yml"
    run "ln -nfs #{deploy_to}/shared/abacos.yml #{version_path}/config/abacos.yml"
    run "ln -nfs #{deploy_to}/shared/unicorn.conf.rb #{version_path}/config/unicorn.conf.rb"
  end

  de  desc 'Run migrations'
  task :rake_tasks, :role => :db do
    run "cd #{path_app} && #{bundle} exec #{rake} db:migrate RAILS_ENV=#{rails_env}", :roles => :db
    run "cd #{path_app} && #{bundle} exec #{rake} olook:create_permissions RAILS_ENV=#{rails_env}", :roles => :db
  end

sc 'Restart unicorn'
  task :restart, :roles => :app do
    run "if [ -f /var/run/olook-unicorn.pid ]; then pid=`cat /var/run/olook-unicorn.pid` && kill -USR2 $pid; else cd #{current_path} && bundle exec unicorn_rails -c #{current_path}/config/unicorn.conf.rb -E #{rails_env} -D; fi"
  end
end
