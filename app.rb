require 'rack'
require 'redis'
require 'scorched'
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
require 'faye'

Faye::WebSocket.load_adapter('thin')

ActiveRecord::Base.establish_connection(
  :adapter  => 'postgresql',
  :host     => 'localhost',
  :username => 'piper',
  :password => 'piper',
  :database => 'portly',
  :pool => 5
)

redis_host, redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
Redis.current = Redis.new(:host => redis_host, :port => redis_port.to_i)

Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/config/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/controllers/*.rb'].each {|file| require file }
