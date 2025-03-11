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
append :linked_files,
       'config/honeybadger.yml' # in shared_configs

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

# honeybadger_env otherwise defaults to rails_env
set :honeybadger_env, fetch(:stage)

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

namespace :pydeps do
  desc 'Install python dependencies'
  task :install do
    on roles(:app) do
      within("#{current_path}/pywb") do
        # Make sure python executables are on the PATH
        with(path: '$HOME/.local/bin:$PATH') do
          execute :pip3, :install, '--user', '--upgrade', 'pipx'
          execute :pipx, :install, 'uv', '--force'
          # ensure latest uv -- pipx install doesn't have an --upgrade flag
          execute :pipx, :upgrade, 'uv'
          execute :uv, :sync, '--python', '3.11'
        end
      end
    end
  end
end

# update shared_configs before restarting app (from dlss-capistrano gem)
before 'deploy:publishing', 'shared_configs:update'
after 'deploy:publishing', 'uwsgi:restart'
before 'uwsgi:restart', 'pydeps:install'
