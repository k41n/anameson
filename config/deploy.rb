ssh_options[:forward_agent] = true
default_run_options[:pty] = true

set :application, "anameson.kodep.ru"
set :deploy_to, "/var/www/railsapps/anameson.kodep.ru"
set :depoly_via, :remote_cache
set :keep_releases, 5

set :scm, :git
set :repository,  "git@github.com:k41n/anameson.git"
set :normalize_asset_timestamps, false

set :user, "railrunner"
set :use_sudo, true
set :files_owner, "railrunner"
set :files_group, "railrunner"

set :migrate_env, "RAILS_ENV=production"

role :web, "dd.kodep.ru"
role :app, "dd.kodep.ru"
role :db,  "dd.kodep.ru"

set :db_host, "127.0.0.1"
set :db_name, "anameson_ru_production"
set :db_user, "railrunner"
set :db_pass, 'bay2Zo7phaek'

# Add RVM's lib directory to the load path.
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

# Load RVM's capistrano plugin.
require "rvm/capistrano"

set :rvm_ruby_string, '1.9.3'
set :rvm_type, :user

depend :remote, :command, "git"
depend :remote, :gem, "bundler"
depend :remote, :directory, "/var/www/railsapps/anameson.kodep.ru"
depend :remote, :directory, "/var/www/railsapps/anameson.kodep.ru/shared"

after "deploy:update_code", :generate_database_yml
after "deploy:update_code", "deploy:set_file_rights"
after "deploy:update_code", "deploy:migrate"
after "deploy:update_code", :setup_symlinks
after "deploy:update_code", :build_assets
after "deploy",             "deploy:cleanup"


desc <<-DESC
  Generates database.yml
DESC
task :generate_database_yml, :roles => :app do
  template = File.read("config/database.yml.erb")
  file_path = File.join(release_path, "config", "database.yml")
  conf = ERB.new(template).result(binding)
  put(conf, file_path)
end
task :build_assets, :roles => :app do
  run "cd #{release_path} && rake RAILS_ENV=production assets:precompile"
  #  run "cp #{release_path}/public/config.js #{release_path}/public/assets/"
end

task :setup_symlinks, :roles => :app do
  run "mkdir -p #{shared_path}/reports && mkdir -p #{shared_path}/sockets && mkdir -p #{release_path}/tmp"
  run "ln -nfs #{shared_path}/reports #{release_path}/reports"
  run "ln -nfs #{shared_path}/sockets #{release_path}/tmp/sockets"
  run "ln -nfs #{shared_path}/system #{release_path}/system"
end
namespace :deploy do
  desc <<-DESC
    Migrates DB from PRIMARY app server (must be set). Used \
    when project code is not deployed to DB serv. \
    P.S. It`s same task as default capistrano, only :roles is changed.
  DESC
  task :migrate do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:rails_env, "production")
    migrate_env = fetch(:migrate_env, "")
    migrate_target = fetch(:migrate_target, :latest)

    directory = case migrate_target.to_sym
      when :current then current_path
      when :latest  then current_release
      else raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
    end
    run "cd #{directory}; bundle install"
    run "cd #{directory}; #{rake} RAILS_ENV=#{rails_env} #{migrate_env} db:migrate --trace"
  end

  task :set_file_rights, :roles => :app do
    run "chmod 750 /var/www/railsapps && chmod 771 #{deploy_to} && chmod 771 #{shared_path}"
    run "chown -R #{files_owner} #{deploy_to} && chgrp -R #{files_group} #{deploy_to}"
    run "chmod 771 #{release_path}"
  end

  desc <<-DESC
    Start the application servers.
  DESC
  task :start, :roles => :app do
    run "bluepill #{application} start"
  end

  desc <<-DESC
    Restart the application servers.
  DESC
  task :restart, :roles => :app do
    run "bluepill --no-privileged load #{release_path}/config/production.pill"
    run "bluepill --no-privileged #{application} restart"
  end

  desc <<-DESC
    Stop the application servers.
  DESC
  task :stop, :roles => :app do
    run "bluepill #{application} stop"
  end

  desc <<-DESC
    Show status of the application servers.
  DESC
  task :status, :roles => :app do
    run "bluepill #{application} status"
  end
end
