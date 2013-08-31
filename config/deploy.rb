require "bundler/capistrano"
require "capistrano-rbenv"

server "176.58.97.199", :app, :web, :db, :primary => true
set :port, 8222
set :application, "realty"
set :repository,  "ssh://git@inmyhouse.su:8222/~/projects/realty.git"
set :scm, :git
set :stage, "production"
set :rack_env, "production"
set :use_sudo,    false
set :user, "deploy"
set :deploy_to, "/home/deploy/#{application}"
set :keep_releases, 10
set :rbenv_ruby_version, "2.0.0-p247"

set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"


# set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

#role :web, "your web-server here"                          # Your HTTP server, Apache/etc
#role :app, "your app-server here"                          # This may be the same as your `Web` server
#role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
#role :db,  "your slave db-server here"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

namespace :deploy do
  task :start do 
  end

  task :stop do 
  end

  task :restart do 
  end
end
