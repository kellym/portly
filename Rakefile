require './app'

#require 'bundler/setup'
#require 'logger'

namespace :db do
  desc "Migrate the database through scripts in db/migrate. Target specific version with VERSION=x"
  task :migrate => :environment do
    ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
  end

  desc "Rollback the database through scripts in db/migrate. Target specific steps with STEPS=x"
  task :rollback => :environment do
    ActiveRecord::Migrator.rollback('db/migrate', ENV["STEPS"] ? ENV["STEPS"].to_i : 1 )
  end

  desc "Seeds the database with the information in db/seeds.rb"
  task :seed => :migrate do
    ActiveRecord::Base.transaction do
      require './db/seeds'
    end
  end

  desc "create an ActiveRecord migration in ./db/migrate"
  task :create_migration do
    name = ENV['NAME']
    abort("no NAME specified. use `rake db:create_migration NAME=create_users`") if !name

    migrations_dir = File.join("db", "migrate")
    version = ENV["VERSION"] || Time.now.utc.strftime("%Y%m%d%H%M%S")
    filename = "#{version}_#{name}.rb"
    migration_name = name.gsub(/_(.)/) { $1.upcase }.gsub(/^(.)/) { $1.upcase }

    FileUtils.mkdir_p(migrations_dir)

    open(File.join(migrations_dir, filename), 'w') do |f|
      f << (<<-EOS).gsub("      ", "")
      class #{migration_name} < ActiveRecord::Migration
        def change

        end
      end
      EOS
    end
  end

  task :environment do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  end
end

