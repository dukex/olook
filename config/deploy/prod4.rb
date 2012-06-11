role :app, 'app4.olook.com.br'

# server details
set :rails_env, 'RAILS_ENV=production'
set :env, 'production'

# repo details
set :branch, fetch(:branch, 'master')

trap("INT") {
  print "\n\n"
  exit 42
}

namespace :log do
  desc "Tail all application log files"
  task :tail, :roles => :web do

    run "tail -f #{path_log}" do |channel, stream, data|
      puts "\033[0;33m#{stage}:\033[0m #{data}"
      break if stream == :err
    end
  end
end

# tasks
namespace :deploy do
  task :default, :roles => :web do
    update #capistrano internal default task
    yml_links
    bundle_install
    rake_tasks
    restart
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
  task :yml_links, :roles => :web do
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

  desc 'Stop unicorn'
  task :stop_unicorn, :roles => :web do
    run "if [ -f /var/run/olook-unicorn.pid ]; then pid=`cat /var/run/olook-unicorn.pid` && kill -TERM $pid; fi"
  end

  desc 'Start unicorn'
  task :start_unicorn, :roles => :app do
    run "cd #{current_path} && bundle exec unicorn_rails -c #{current_path}/config/unicorn.conf.rb -E #{env} -D"
  end

  desc 'Restart unicorn'
  task :restart, :roles => :web do
    run "if [ -f /var/run/olook-unicorn.pid ]; then pid=`cat /var/run/olook-unicorn.pid` && kill -USR2 $pid; else cd #{current_path} && bundle exec unicorn_rails -c #{current_path}/config/unicorn.conf.rb -E #{env} -D; fi"
  end

  after "deploy", "deploy:cleanup" # keep only the last 5 releases
end
