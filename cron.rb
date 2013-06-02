#!/usr/bin/env ruby

require 'clockwork'
require 'redis'
require 'active_record'

Thread.new do

  @redis_host, @redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
  Redis.current = Redis.new(:host => @redis_host, :port => @redis_port.to_i)

  database_setup = YAML.load(File.read('config/database.yml'))
  ActiveRecord::Base.establish_connection database_setup[ENV['RACK_ENV']]

  module Clockwork

    every(1.day, 'rotate_bytes', at: '00:00') do
      Redis.current.keys('bytes:*').each do |key|
        bytes = Redis.current.get(key)
        connector_id = key.split(':').last
        ActiveRecord::Base.connection.execute("INSERT INTO connector_bytes (connector_id, bytes, created_at) VALUES('#{connector_id}', '#{bytes}', '#{Date.yesterday}')")
        Redis.current.set key, 0
      end
    end


  end
  Clockwork::run

end

sleep
