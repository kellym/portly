require './app'
require 'uglifier'
require 'yui/compressor'

#require 'bundler/setup'
#require 'logger'
task :environment do
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end

namespace :db do
  require "activerecord-postgres-array/activerecord"
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

namespace :versions do

  desc 'synchronize all versions'
  task :sync do
    Dir[File.dirname(__FILE__) + '/public/downloads/portly*.zip'].each do |file|
      filename = file.split('/').last.gsub(/\.[^\.]*$/, '')
      file_default, version, number = filename.split('-')

      if file_default == 'portly' && !Version.where(version: version).exists?
        openssl = "/usr/bin/openssl"
        dsa = `#{openssl} dgst -sha1 -binary < "#{file}" | #{openssl} dgst -dss1 -sign "#{File.dirname(__FILE__) + '/dsa_priv.pem'}" | #{openssl} enc -base64`
        filesize = File.size(file)
        notes = ENV['SINGLE'] ? ENV['NOTES'] : ''
        Version.create(title: "Version #{version}", number: number, version: version, dsa: dsa, filesize: filesize, notes: notes)
        break if ENV['SINGLE']
        sleep 3 # so timestamps are different
      end
    end
  end

  task :add do
    ENV['SINGLE'] = 'true'
    Rake::Task["versions:sync"].execute
  end

end

namespace :sitemap do

  desc 'generates the sitemap'
  task :generate do
    require ROOT_PATH + "/config/sitemap.rb"
    controller_path = ROOT_PATH + "/controllers/"
    view_path = ROOT_PATH + "/views/"
    sitemap = %Q[<?xml version="1.0" encoding="UTF-8"?>\n]
    sitemap << %Q[<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n]
    SITEMAP.values.each do |url|
      if url[:lastmod]
        if url[:lastmod].is_a? Proc
          lastmod = url[:lastmod].call
        elsif url[:lastmod].is_a? String
          lastmod = url[:lastmod]
        else
          lastmod = url[:lastmod].to_s(:db)
        end
      else
        lastmod = Time.new(2013, 3, 15)
        if url[:controller]
          newmod = File.mtime("#{controller_path}#{url[:controller]}_controller.rb")
          lastmod = newmod if lastmod < newmod
        end
        if url[:view]
          newmod = File.mtime("#{view_path}#{url[:view]}")
          lastmod = newmod if lastmod < newmod
        end
        if url[:file]
          newmod = File.mtime("#{ROOT_PATH}#{url[:file]}")
          lastmod = newmod if lastmod < newmod
        end
        lastmod = lastmod.to_s(:db)
      end
      sitemap += <<URL
  <url>
    <loc>https://portly.co#{url[:url]}</loc>
    <lastmod>#{lastmod}</lastmod>
    <changefreq>#{url[:changefreq] || 'weekly'}</changefreq>
    <priority>#{url[:priority] || 0.5}</priority>
  </url>
URL
    end
    sitemap << File.read(ROOT_PATH + "/blog/sitemap.xml")
    sitemap << "</urlset>";
    File.open(ROOT_PATH + "/public/sitemap.xml", "w+") do |f|
      f.write sitemap
    end
    File.open(ROOT_PATH + "/public/sitemap.xml.gz", "w+") do |f|
      gz = Zlib::GzipWriter.new(f)
      gz.write sitemap
      gz.close
    end
  end
end
