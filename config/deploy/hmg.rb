role :app, "homolog.olook.com.br"
role :web, "homolog.olook.com.br"
 
# server details
set :rails_env, 'staging'

# repo details
set :branch, fetch(:branch, 'homolog')

# tasks
namespace :deploy do

  namespace :assets do
    task :precompile, :roles => :web do
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec rake assets:precompile"
    end
  end

  task :default, :role => :app do
    update #capistrano internal default task
    yml_links
    rake_tasks
    restart
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

  desc 'Run migrations'
  task :rake_tasks, :role => :app do
    run "cd #{path_app} && bundle exec rake db:migrate RAILS_ENV=#{rails_env}"
    run "cd #{path_app} && bundle exec rake olook:create_permissions RAILS_ENV=#{rails_env}"
  end

  desc 'Restart webserver'
  task :restart, :roles => :app do
    run "ps -e -o pid,command |grep unicorn |grep master"
    run "if [ -f /var/run/olook-unicorn.pid ]; then pid=`cat /var/run/olook-unicorn.pid` && kill -USR2 $pid; else cd #{current_path} && bundle exec unicorn_rails -c #{current_path}/config/unicorn.conf.rb -E #{rails_env} -D; fi"
    run "ps -e -o pid,command |grep unicorn |grep master"
  end

# desc "Make sure local git is in sync with remote."
# task :check_revision, roles: :web do
#   unless `git rev-parse HEAD` == `git rev-parse origin/master`
#     puts "WARNING: HEAD is not the same as origin/master"
#     puts "Run `git push` to sync changes."
#     exit
#   end
# end
#
# before "deploy", "deploy:check_revision"

#Ao utilizar o callback after dessa forma, o Unicorn será reiniciado 2x, 1X pela task default do deploy e 1x pelo callback
  #after 'deploy', 'deploy:yml_links'
  #after 'deploy:yml_links', 'deploy:bundle_install'
  #after 'deploy:bundle_install', 'deploy:restart'

#ROLL BACK de migration
  # configuration = Capistrano::Configuration.respond_to?(:instance) ?
  #   Capistrano::Configuration.instance(:must_exist) :
  #   Capistrano.configuration(:must_exist)

  # configuration.load do
  #   namespace :deploy do    
  #     namespace :rollback do
  #       desc <<-DESC
  #                         Rolls back the migration to the version found in schema.rb file of the previous release path.\\
  #                               Uses sed command to read the version from schema.rb file.
  #       DESC
  #       task :migrations do
  #         run "cd #{current_release};  rake db:migrate RAILS_ENV=#{rails_env} VERSION=`grep \\":version =>\\" #{previous_release}/db/schema.rb | sed -e 's/[a-z A-Z = \\> \\: \\. \\( \\)]//g'`"
  #       end
  #       after "deploy:rollback","deploy:rollback:migrations"
end
