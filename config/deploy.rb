# frozen_string_literal: true

set :application, 'was-pywb'
set :repo_url, "https://github.com/sul-dlss/#{fetch(:application)}.git"

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/was/swap'

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", 'config/master.key'

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

namespace :uwsgi do
  desc 'Display uWSGI status'
  task :status do
    on roles(:app) do
      sudo :systemctl, 'status', 'uwsgi'
    end
  end

  desc 'Stop uWSGI service'
  task :stop do
    on roles(:app) do
      sudo :systemctl, 'stop', 'uwsgi'
    end
  end

  desc 'Start uWSGI service'
  task :start do
    on roles(:app) do
      sudo :systemctl, 'start', 'uwsgi'
    end
  end

  desc 'Restart uWSGI service'
  task :restart do
    on roles(:app) do
      sudo :systemctl, 'restart', 'uwsgi', raise_on_non_zero_exit: false
    end
  end
end

namespace :pip do
  desc 'Install python dependencies via pip'
  task :install do
    on roles(:app) do
      within "#{current_path}/pywb" do
        execute :pip3, :install, '-r requirements.txt'
      end
    end
  end
end

before 'deploy:updated', 'pip:install'
before 'deploy:reverted', 'pip:install'
after 'deploy:publishing', 'uwsgi:restart'
