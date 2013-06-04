#!/usr/bin/env ruby

require 'clockwork'
require 'redis'
require 'active_record'

Thread.new do

  ROOT_PATH = File.dirname(__FILE__)
  if ENV['RACK_ENV'] == 'development'
    LOG = Logger.new STDOUT
  else
    LOG = Logger.new(ROOT_PATH + '/log/' + (ENV['RACK_ENV'] || 'development') + '.log', 'daily')
  end
  LOG.level = Logger::DEBUG

  @redis_host, @redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
  Redis.current = Redis.new(:host => @redis_host, :port => @redis_port.to_i)

  database_setup = YAML.load(File.read('config/database.yml'))
  ActiveRecord::Base.establish_connection database_setup[ENV['RACK_ENV']]

  module Clockwork

    every(1.day, 'rotate_bytes', at: '05:00') do # midnight CST
      Redis.current.keys('bytes:*').each do |key|
        bytes = Redis.current.hgetall(key)
        connector_id = key.split(':').last
        ActiveRecord::Base.connection.execute("INSERT INTO connector_bytes (connector_id, bytes_total, bytes_in, bytes_out, created_at) VALUES('#{connector_id}', '#{bytes['in'].to_i + bytes['out'].to_i}', '#{bytes['in']}', '#{bytes['out']}', '#{Date.yesterday}')")
        Redis.current.del key
      end
    end


  end
  begin
    Clockwork::run
  rescue => e
    LOG.debug "CRON-ERROR"
    LOG.debug e.message
  end

end

sleep
