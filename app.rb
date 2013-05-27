require 'rubygems'
require 'rack'
require 'redis'
require 'scorched'
require 'coffee_script'
require 'kgio'
require 'rack/session/dalli'
require 'hashie'
require 'active_record'
require 'rack/rest_api_versioning'
require 'sass'
require 'sshkey'
require 'haml'
require 'json'
require 'socket'
require 'sprockets'
require 'bcrypt'
require 'haml'
require 'eventmachine'
require 'thin'
require 'active_support/core_ext/integer/inflections'
require 'omniauth'
require 'omniauth-github'
require 'msgpack'
require 'mail'

ROOT_PATH = File.dirname(__FILE__)

@redis_host, @redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
Redis.current = Redis.new(:host => @redis_host, :port => @redis_port.to_i)
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
require_relative 'config/settings'

ActiveRecord::Base.establish_connection(
  :adapter  => 'postgresql',
  :host     => 'localhost',
  :username => 'piper',
  :password => 'piper',
  :database => 'portly',
  :pool => 5
)

Mail.defaults do
  puts 'Configuring email'
  delivery_method :smtp, {
    address: App.config.mail.address,
    port:    App.config.mail.port
  }
end

Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/mailers/*.rb'].each {|file| require file }
require_relative 'controllers/application_controller'
