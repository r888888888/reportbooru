# config valid only for current version of Capistrano
lock '3.4.0'

set :stages, %w(production staging)
set :default_stage, "staging"
set :application, 'reportbooru'
set :repo_url, 'git://github.com/r888888888/reportbooru.git'
set :user, "danbooru"
set :deploy_to, "/var/www/reportbooru"
set :default_env, {
  "PATH" => '$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH',
  "RAILS_ENV" => "production"
}

require 'capistrano/bundler'
set :bundle_bins, fetch(:bundle_bins, ["gem", "rake", "rails"]).push("unicorn")
set :bundle_flags, "--deployment --quiet --binstubs --shebang ruby"

require 'capistrano3/unicorn'
set :unicorn_roles, [:app]
set :unicorn_pid, "/var/www/reportbooru/shared/pids/unicorn.pid"
set :unicorn_config_path, -> { File.join(current_path, "config", "unicorn", "#{fetch(:stage)}.rb") }
set :unicorn_rack_env, -> { fetch(:stage) == "development" ? "development" : "deployment" }
set :unicorn_restart_sleep_time, 3

require 'whenever/capistrano'

after 'deploy:publishing', 'unicorn:reload'
