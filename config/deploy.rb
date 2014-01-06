require 'mina/bundler'
require 'mina/rails'
require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
# require 'mina/rvm'    # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :domain, 'portly.co'
set :deploy_to, '/var/www/portly'
set :repository, 'git@github.com:kellym/portly.git'
set :branch, 'master'
set :rbenv_path, '/usr/local/rbenv/versions/2.0.0-p195/bin/:/usr/local/rbenv'
set :bundle_prefix, 'source /var/www/portly/shared/config/env.sh && bundle exec'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/database.yml', 'log', 'public/downloads', 'blog']

# Optional settings:
set :user, 'portly'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .rbenv-version to your repository.
  invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'
end

# encoding: utf-8

# # Modules: Git
# Adds settings and tasks related to managing Git.
#
#     require 'mina/git'

# ## Settings
# Any and all of these settings can be overriden in your `deploy.rb`.

# ### branch
# Sets the branch to be deployed.

set_default :branch, 'master'

namespace :git do
  # ## Deploy tasks
  # These tasks are meant to be invoked inside deploy scripts, not invoked on
  # their own.

  # ### git:clone
  # Clones the Git repository. Meant to be used inside a deploy script.

  desc "Clones the Git repository to the release path."
  task :clone do
    if revision?
      error "The Git option `:revision` has now been deprecated."
      error "Please use `:commit` or `:branch` instead."
      exit
    end

    clone = if commit?
      %[
        echo "-----> Using git commit '#{commit}'" &&
        #{echo_cmd %[git clone "#{repository!}" . --recursive]} &&
        #{echo_cmd %[git checkout -b current_release "#{commit}" --force]} &&
        echo
      ]
    else
      %{
        if [ ! -d "#{deploy_to}/scm/objects" ]; then
          echo "-----> Cloning the Git repository"
          #{echo_cmd %[git clone "#{repository!}" "#{deploy_to}/scm" --bare]}
        else
          echo "-----> Fetching new git commits"
          #{echo_cmd %[(cd "#{deploy_to}/scm" && git fetch "#{repository!}" "#{branch}:#{branch}" --force)]}
        fi &&
        echo "-----> Using git branch '#{branch}'" &&
        #{echo_cmd %[git clone "#{deploy_to}/scm" . --recursive --branch "#{branch}"]} &&
        echo
      }
    end

    queue clone
  end

  desc "Cleans the git stuff out after a deploy."
  task :clean do
    status = %[
      echo "-----> Using this git commit" &&
      echo &&
      #{echo_cmd %[git --no-pager log --format="%aN (%h):%n> %s" -n 1]} &&
      #{echo_cmd %[rm -rf .git]} &&
      echo
    ]

    queue status
  end
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]

  queue! %[touch "#{deploy_to}/shared/config/database.yml"]
end

task :'db:migrate' => :environment do
  queue! %[cd /var/www/portly/current/ && #{bundle_prefix} rake db:migrate]
end

task :'versions:sync' => :environment do
  queue! %[cd /var/www/portly/current/ && #{bundle_prefix} rake versions:sync]
end

task :'versions:add' => :environment do
  queue! %[cd /var/www/portly/current/ && #{bundle_prefix} rake versions:add NOTES="#{ENV['NOTES']}"]
end

task :'assets:compile' => :environment do
  queue! %[#{bundle_prefix} rake assets:compile VERSION=$version]
end

task :get_release => :environment do
  queue! %[sed -i "s/ASSETS_VERSION=.*/ASSETS_VERSION=$version/g" #{deploy_to}/shared/config/env.sh ]
end

task :'thin:restart' => :environment do
  queue! %[cd /var/www/portly/current/ && #{bundle_prefix} thin restart --debug -C /etc/thin/portly.yml]
end

task :'cron:start' => :environment do
  queue! %[eye start portly:cron]
end
task :'cron:stop' => :environment do
  queue! %[eye stop portly:cron]
end

task :'data_monitor:start' => :environment do
  queue! %[eye start portly:data_monitor]
end
task :'data_monitor:stop' => :environment do
  queue! %[eye stop portly:data_monitor]
end

task :'socket:start' => :environment do
  queue! %[cd /var/www/portly/current/ && #{bundle_prefix} ruby tracking_control.rb start && #{bundle_prefix} ruby tracking_control.rb start && #{bundle_prefix} ruby server_control.rb start]
end
task :'socket:stop' => :environment do
  queue! %[cd /var/www/portly/current/ && #{bundle_prefix} ruby tracking_control.rb stop && #{bundle_prefix} ruby server_control.rb stop]
end
task :'socket:restart' => :environment do
  queue! %[cd /var/www/portly/current/ && #{bundle_prefix} ruby tracking_control.rb restart && #{bundle_prefix} ruby server_control.rb restart]
end

task :'sitemap:generate' => :environment do
  queue! %[#{bundle_prefix} rake sitemap:generate]
end

task :tux => :environment do
  queue! %[cd /var/www/portly/current/ && #{bundle_prefix} tux]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  #invoke :'socket:stop'
  #invoke :'data_monitor:stop'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'sitemap:generate'
    invoke :'assets:compile'
    invoke :'git:clean'

    #invoke :'rails:assets_precompile'
    to :launch do
      invoke :get_release
      invoke :'db:migrate'
      invoke :'thin:restart'
      #invoke :'socket:start'
      #invoke :'data_monitor:start'
      # set up launch agent
    end
  end
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers

