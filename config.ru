$stdout.sync = true
require './app'

use ActiveRecord::ConnectionAdapters::ConnectionManagement
use Rack::ActiveRecord
use Rack::Session::Dalli,
  :compression => true,
  :memcache_server => 'localhost:11211',
  :expire_after => ::App.config.memcache.expires,
  :namespace => ::App.config.memcache.namespace,
  :key => '_sess',
  :secure => ::App.config.memcache.secure
use Warden::Manager do |config|
  config.default_scope = :user
  config.scope_defaults :user,
    :strategies => [:password],
    :action     => 'unauthenticated'
  config.scope_defaults :api,
    :strategies => [:api_token, :api_password, :password],
    :action     => 'api/unauthenticated'
  config.scope_defaults :basic,
    :strategies => [:basic],
    :action     => 'basic_auth'
  config.failure_app = ApplicationController
end
use Rack::CommonLogger
use OmniAuth::Builder do
  provider :github, ::App.config.github_key, ::App.config.github_secret
end


# Airbrake
Airbrake.configure do |config|
  config.api_key = 'e3008a5af646469d059e3cd9f5d85ac7'
end
use Airbrake::Rack

# Dragonfly
use Rack::Cache,
  :verbose     => true,
  :metastore   => URI.encode("file:#{::App.config.tmp_path}/cache/meta"),
  :entitystore => URI.encode("file:#{::App.config.tmp_path}/cache/body")

use Dragonfly::Middleware, :images

run ApplicationController

Thread.new do
  begin
    STDOUT.sync = true
    @redis_host, @redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
    redis = Redis.new(:host => @redis_host, :port => @redis_port.to_i)
    LOG.debug "connecting to redis again on #{@redis_port} for sockets"
    redis.subscribe('socket_monitor', 'socket_publisher') do |on|
      # When a message is published to 'em'
      on.message do |chan, msg|
        LOG.debug chan
        LOG.debug msg
        case chan
        when 'socket_monitor'
          socket, action, *args = msg.split(':')
          LOG.debug "sending message on #{socket}: #{action}"
          # Send out the message on each open socket
          if action == 'socket' && args.first == 'off'
            # kill all the connectors this way, since sometimes they can stagnate
            token = Token.where(:code => socket).first
            token.disconnect
          else
            token = Token.select('tokens.id, tokens.user_id').where(:code => socket).first
          end
          EventSource.publish_to_user(token.user_id, "#{action}", { id: token.id, args: args })
        when 'socket_publisher'
          unpacked = MessagePack.unpack(msg)
          LOG.debug unpacked.inspect
          EventSource.publish_to_user(unpacked['user_id'], unpacked['action'], unpacked['data'])
        end
      end
    end
  rescue => error
    LOG.error error.to_s
    sleep 1
    retry
  end
end

Thread.new do
  begin
    $stdout.sync = true
    @redis_host, @redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
    LOG.debug "connecting to redis again on #{@redis_port}"
    redis = Redis.new(:host => @redis_host, :port => @redis_port.to_i)
    redis.subscribe('email_monitor') do |on|
      # When a message is published to 'em'
      on.message do |chan, msg|
        args = MessagePack.unpack(msg)
        klass = args.shift
        action = args.shift
        puts "Sending email: #{klass}##{action} #{args.inspect}"
        klass.constantize.create(action.to_sym, *args).deliver
      end
    end
  rescue => error
    LOG.error error.to_s
    sleep 1
    retry
  end
end

run ApplicationController
