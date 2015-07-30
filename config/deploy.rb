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

after 'deploy:publishing', 'unicorn:reload'
