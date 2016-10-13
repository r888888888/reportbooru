# config valid only for current version of Capistrano
#lock '3.4.0'

set :stages, %w(production staging)
set :default_stage, "staging"
set :application, 'reportbooru'
set :repo_url, 'git://github.com/r888888888/reportbooru.git'
set :user, "danbooru"
set :deploy_to, "/var/www/reportbooru"
set :scm, :git
set :default_env, {
  "PATH" => '$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH',
  "RAILS_ENV" => "production"
}
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle')
set :linked_files, fetch(:linked_files, []).push("config/application.yml", "google-key.json")
set :rbenv_ruby, "2.3.1"

after 'deploy:publishing', 'unicorn:restart'
