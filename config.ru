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
  provider :github, App.config.github_key, App.config.github_secret
end

Airbrake.configure do |config|
  config.api_key = 'e3008a5af646469d059e3cd9f5d85ac7'
end

use Airbrake::Rack

run ApplicationController

Thread.new do
  $stdout.sync = true
  @redis_host, @redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
  puts "connecting to redis again on #{@redis_port}"
  redis = Redis.new(:host => @redis_host, :port => @redis_port.to_i)
  redis.subscribe('socket_monitor') do |on|
    # When a message is published to 'em'
    on.message do |chan, msg|
      socket, action, *args = msg.split(':')
      puts "sending message on #{socket}: #{action}"
      # Send out the message on each open socket
      if action == 'socket' && args.first == 'off'
        # kill all the connectors this way, since sometimes they can stagnate
        token = Token.where(:code => socket).first
        token.disconnect
      else
        token = Token.select('tokens.id, tokens.user_id').where(:code => socket).first
      end
      EventSource.publish(token.user_id, "#{action}", { id: token.id, args: args })
    end
  end
end

Thread.new do
  $stdout.sync = true
  @redis_host, @redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
  puts "connecting to redis again on #{@redis_port}"
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

end
#  thin = Rack::Handler.get('thin')

#  thin.run(ApplicationController, :Port => 9393) do |server|
    # You can set options on the server here, for example to set up SSL:
    #server.ssl_options = {
    #  :private_key_file => 'path/to/ssl.key',
    #  :cert_chain_file  => 'path/to/ssl.crt'
    #}
    #server.ssl = true
#  end

#}
#if ENV['RACK_ENV'] == 'development'

run ApplicationController

#else
#  EM.run {
#    thin = Rack::Handler.get('thin')
#
#    thin.run(ApplicationController, :Port => 9393) do |server|
#      # You can set options on the server here, for example to set up SSL:
#      #server.ssl_options = {
#      #  :private_key_file => 'path/to/ssl.key',
#      #  :cert_chain_file  => 'path/to/ssl.crt'
#      #}
#      #server.ssl = true
#    end
#
#  }
#end
