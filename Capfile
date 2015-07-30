# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

require 'whenever/capistrano'

require 'capistrano/bundler'

require 'capistrano3/unicorn'
set :unicorn_pid, "/var/www/reportbooru/shared/pids/unicorn.pid"

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
