$stdout.sync = true
require './app'

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
            token.disconnect if token
          else
            token = Token.select('tokens.id, tokens.user_id').where(:code => socket).first
          end
          EventSource.publish_to_user(token.user_id, "#{action}", { id: token.id, args: args }) if token
        when 'socket_publisher'
          unpacked = MessagePack.unpack(msg)
          LOG.debug unpacked.inspect
          EventSource.publish_to_user(unpacked['user_id'], unpacked['action'], unpacked['data'])
        end
      end
    end
  rescue => error
    LOG.error "SOCKET_MONITOR: #{error.to_s}"
    sleep 1
    retry
  end
end

# Email Monitor
Thread.new do
  begin
    $stdout.sync = true
    @redis_host, @redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
    LOG.debug "Email monitor: connecting to redis again on #{@redis_port}"
    redis = Redis.new(:host => @redis_host, :port => @redis_port.to_i)
    loop do
      msg = redis.brpoplpush 'email_monitor', 'email_monitor:working', 0
      args = MessagePack.unpack(msg)
      uuid = args.shift
      klass = args.shift
      action = args.shift
      puts "Sending email: #{klass}##{action} #{args.inspect}"
      klass.constantize.create(action.to_sym, *args).deliver
      redis.lrem 'email_monitor:working', -1, msg
    end
  rescue => error
    LOG.error "EMAIL_MONITOR: #{error.to_s}"
    sleep 1
    retry
  end
end

# Queueable
Thread.new do
  begin
    $stdout.sync = true
    @redis_host, @redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
    LOG.debug "Queueable: connecting to redis again on #{@redis_port}"
    redis = Redis.new(:host => @redis_host, :port => @redis_port.to_i)
    loop do
      msg = redis.brpoplpush 'queue_monitor', 'queue_monitor:working', 0
      args = MessagePack.unpack(msg)
      klass = args.shift
      puts "putting class: #{klass} with action."
      # action = args.shift
      klass.constantize.new(*args).perform
      redis.lrem 'queue_monitor:working', -1, msg
    end
  rescue => error
    LOG.error "QUEUE_MONITOR: #{error.to_s}"
    sleep 1
    retry
  end
end

run ApplicationController
