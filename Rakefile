require './app'
require 'uglifier'
require 'yui/compressor'

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


namespace :assets do

  sprockets = Sprockets::Environment.new
  sprockets.append_path 'assets/javascripts'
  sprockets.append_path 'assets/stylesheets'
  sprockets.js_compressor  = Uglifier.new(mangle: true)
  sprockets.css_compressor = YUI::CssCompressor.new

  desc 'compile assets'
  task :compile => [:compile_js, :compile_css] do
  end

  desc 'compile javascript assets'
  task :compile_js do
    version = ENV['VERSION']
    Dir[File.dirname(__FILE__) + '/assets/javascripts/*.coffee'].each do |file|
      asset     = sprockets[file]
      outpath   = App.config.assets_path
      outfile   = Pathname.new(outpath).join("#{file.split('/').last.split('.').first}.#{version}.js")
      FileUtils.mkdir_p outfile.dirname
      asset.write_to(outfile)
      asset.write_to("#{outfile}.gz")
    end
    puts "Successfully compiled javascript assets."
  end

  desc 'compile javascript assets'
  task :compile_css do
    version = ENV['VERSION']
    Dir[File.dirname(__FILE__) + '/assets/stylesheets/*.sass'].each do |file|
      asset     = sprockets[file]
      outpath   = App.config.assets_path
      outfile   = Pathname.new(outpath).join("#{file.split('/').last.split('.').first}.#{version}.css")
      FileUtils.mkdir_p outfile.dirname
      asset.write_to(outfile)
      asset.write_to("#{outfile}.gz")
    end
    puts "Successfully compiled CSS assets."
  end
  # todo: add :clean_all, :clean_css, :clean_js tasks, invoke before writing new file(s)
end
