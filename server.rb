#!/usr/bin/env ruby
#
# server_1

require 'rubygems'
require 'eventmachine'
require 'redis'
require 'em-hiredis'
require 'hashie'

$stdout.sync = true

require_relative 'lib/config.rb'
Dir[File.dirname(__FILE__) + '/config/*.rb'].each {|file| require file }

redis_host, redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
Redis.current = Redis.new(:host => redis_host, :port => redis_port.to_i)

SOCKETS = {}

class EventServer < EM::Connection

  def redis
    @redis ||= EM::Hiredis.connect("redis://#{ENV['REDIS_HOST']}")
  end

  def post_init
    @key_path = "/Users/kelly/w/portly/config/server"
    puts "-- someone connected to the echo server at #{Time.now}, setting up #{@key_path}/server.key"
    start_tls :private_key_file => "#{@key_path}/server.key", :cert_chain_file => "#{@key_path}/server.crt", :verify_peer => false
    puts "-- started tls"
    send_data "HELLO\n"
  end

  def receive_data data
    data.chomp!
    #send_data ">>> you sent: #{data}\n"
    case data
    when /^EHLO:(.*)/
      # initially set the socket as online so we can issue commands to it
      token = $1
      SOCKETS[token] = self
      puts "-- setting socket online at #{token}"
      redis.sadd 'sockets_online', token do
        puts "-- socket is set as online at #{token}"
      end
    end
  end

  def unbind
    token = SOCKETS.key(self)
    puts "disconnected from #{token}"
    redis.srem 'sockets_online', token do
      puts '-- socket removed'
    end
  end
end

Thread.new do
  EventMachine::run do
    EventMachine::start_server App.config.event_server.host, App.config.event_server.port, EventServer
    puts "running echo server on #{App.config.event_server.port}"
  end
end

Thread.new do
  Redis.current.psubscribe('socket:*') do |on|
    # When a message is published to 'em'
    on.pmessage do |sub, chan, msg|
      socket = chan.split(':',2).last
      puts "sending message on #{socket}: #{msg}"
      # Send out the message on each open socket
      SOCKETS[socket].send_data msg if SOCKETS.has_key? socket
    end
  end
end

puts "Running..."

sleep
