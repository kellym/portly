$stdout.sync = true
require './app'
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
