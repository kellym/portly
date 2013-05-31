#!/usr/bin/env ruby
#
# server_1

require 'rubygems'
require 'eventmachine'
require 'redis'
require 'em-hiredis'
require 'hashie'
require 'logger'

$stdout.sync = true

require_relative 'lib/config'
require_relative 'config/settings'
redis_host, redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
Redis.current = Redis.new(:host => redis_host, :port => redis_port.to_i)

SOCKETS = {}

ROOT_PATH = File.dirname(__FILE__)
if ENV['RACK_ENV'] == 'development'
  LOG = Logger.new STDOUT
else
  LOG = Logger.new(ROOT_PATH + '/log/' + (ENV['RACK_ENV'] || 'development') + '.log', 'daily')
end
LOG.level = Logger::DEBUG

TIMEOUT = 15

class EventServer < EM::Connection

  def redis
    @redis ||= EM::Hiredis.connect("redis://#{ENV['REDIS_HOST']}")
  end

  def post_init
    @key_path = App.config.server_key_path
    LOG.debug "-- someone connected to the echo server at #{Time.now}, setting up #{@key_path}/server.key"
    start_tls :private_key_file => "#{@key_path}/server.key", :cert_chain_file => "#{@key_path}/server.crt", :verify_peer => false
    LOG.debug "-- started tls"
    send_data "HELLO\n"
    @seconds_waited = 0
    @timer = EventMachine::PeriodicTimer.new(5) do
      @seconds_waited += 5
      if @seconds_waited > TIMEOUT
        self.close_connection
      end
    end
  end

  def receive_data data
    @seconds_waited = 0
    data.chomp!
    case data
    when /^EHLO:(.*)/
      # initially set the socket as online so we can issue commands to it
      token = $1
      @online = Time.now
      ip_address = get_peername[2,6].unpack("nC4")
      ip_address.shift
      @ip_address = ip_address.join '.'
      SOCKETS[token] = self
      LOG.debug "-- setting socket online at #{token}"
      redis.sadd 'sockets_online', token
      LOG.debug "-- publishing that socket is set as online at #{token}"
      redis.publish "track_ip:on", "#{token}|#{@ip_address}|#{@online}"
      redis.publish 'socket_monitor', "#{token}:socket:on"

    when /^STATE:([0-9]+):(.*)/
      connector = $1
      state = $2
      token = SOCKETS.key(self)
      if state == 'on'
        redis.sadd "connectors_enabled:#{token}", connector do
          LOG.debug "-- publishing that connector #{connector} is set as #{state} at #{token}"
          redis.publish 'socket_monitor', "#{token}:state:#{connector}:on"
        end
      else
        redis.srem "connectors_enabled:#{token}", connector do
          LOG.debug "-- publishing that connector #{connector} is set as #{state} at #{token}"
          redis.publish 'socket_monitor', "#{token}:state:#{connector}:off"
        end
      end
    else
      ping
    end
  end

  def ping
    send_data "\n"
  end

  def unbind
    token = SOCKETS.key(self)
    SOCKETS.delete(token)
    LOG.debug "disconnected from #{token}"
    @timer.cancel if @timer
    redis.srem 'sockets_online', token do
      redis.publish "track_ip:off", "#{token}|#{@ip_address}|#{Time.now}|#{@online}"
      redis.publish 'socket_monitor', "#{token}:socket:off"
      LOG.debug '-- socket removed'
    end
  end
end

Thread.new do
  begin
    EventMachine::run do
      EventMachine::start_server App.config.event_server.host, App.config.event_server.port, EventServer
      LOG.debug "running echo server on #{App.config.event_server.port}"
    end
  rescue => error
    LOG.error error.to_s
    sleep 1
    retry
  end
end

Thread.new do
  begin
    Redis.current.psubscribe('socket:*') do |on|
      # When a message is published to 'em'
      on.pmessage do |sub, chan, msg|
        socket = chan.split(':',2).last
        LOG.debug "sending message on #{socket}: #{msg}"
        # Send out the message on each open socket
        SOCKETS[socket].send_data "#{msg}\n\n" if SOCKETS.has_key? socket
      end
    end
  rescue => error
    LOG.error error.to_s
    sleep 1
    retry
  end
end

#require 'active_record'
#Thread.new do
#  database_setup = YAML.load(File.read('config/database.yml'))
#  ActiveRecord::Base.establish_connection database_setup[ENV['RACK_ENV']]
#  Redis.current.subscribe('track_ip') do |on|
#    on.message do |chan, msg|
#      token, ip_address, time = msg.split '|'
#      r = ActiveRecord::Base.connection.execute("SELECT id FROM tokens WHERE code='#{token.gsub(/[^a-zA-Z0-9]/,'')}'")
#      token_id = r.getvalue(0,0)
#      ActiveRecord::Base.connection.execute("INSERT INTO token_records (token_id, ip_address, access_time) VALUES('#{token_id}', '#{ip_address}', '#{time}')")
#    end
#  end
#end

LOG.debug "Running..."

sleep
