# config valid only for current version of Capistrano
lock '3.4.0'

set :stages, %w(production staging)
set :default_stage, "staging"
set :application, 'reportbooru'
set :repo_url, 'git://github.com/r888888888/reportbooru.git'
set :user, "danbooru"
set :deploy_to, "/var/www/reportbooru"
set :default_environment, {
  "PATH" => '$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH'
}
set :whenever_command, "bundle exec whenever"
require 'whenever/capistrano'

namespace :deploy do

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
