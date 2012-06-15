role :app, "q1.olook.com.br", "q2.olook.com.br"

# server details
set :rails_env, "RAILS_ENV=production"

# repo details
set :branch, fetch(:branch, 'master')

# tasks
namespace :deploy do
  task :default, :role => :app do
    update #capistrano internal default task
    yml_links
    bundle_install
    #rake_tasks
    # restart
    #resque_restart
  end

  desc 'Install gems'
  task :bundle_install, :roles => :app do
    run "cd #{path_app} && #{bundle} --without development test install"
  end

  desc 'Run migrations, clean assets'
  task :rake_tasks, :role => :app do
    run "cd #{path_app} && #{bundle} exec #{rake} db:migrate #{rails_env}"
    run "cd #{path_app} && #{bundle} exec #{rake} assets:clean #{rails_env}"
    run "cd #{path_app} && #{bundle} exec #{rake} assets:precompile #{rails_env}"
    run "cd #{path_app} && #{bundle} exec #{rake} olook:create_permissions #{rails_env}"
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
  end

  desc 'Restart webserver'
  task :restart, :roles => :app do
  #  run "/sbin/restart unicorn"
  #  run '/etc/init.d/workers_todos.sh restart'
  end

  desc 'Task to restart resque'
  task :resque_restart, :app => :app do
    #run '/etc/init.d/worker_todos.sh restart'
  end

  after "deploy", "deploy:cleanup" # keep only the last 5 releases
end

