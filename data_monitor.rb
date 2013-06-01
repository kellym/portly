#!/usr/bin/env ruby

$stdout.sync = true
require 'active_record'
require 'file-tail'
require 'redis'

@redis_host, @redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
Redis.current = Redis.new(:host => @redis_host, :port => @redis_port.to_i)
filename = '/var/log/portly.bytes.log'

database_setup = YAML.load(File.read('config/database.yml'))
ActiveRecord::Base.establish_connection database_setup[ENV['RACK_ENV']]

File::Tail::Logfile.open(filename) do |log|

  log.after_reopen do
    bytes_to_record = Redis.current.keys 'bytes:*'
    bytes_to_record.each do |connector|
      bytes = Redis.current.get connector
      connector_id = connector.split(':').last
      ActiveRecord::Base.connection.execute("INSERT INTO connector_bytes (connector_id, bytes, created_at) VALUES('#{connector_id}', '#{bytes}', '#{time}')")
    end
  end

  log.tail do |line|
    connector_id, bytes, timestamp = line.split '|'
    # timestamp = Time.parse(timestamp) rescue Time.now
    bytes = bytes.to_i
    if bytes > 0
      Redis.current.incrby "bytes:#{connector_id}", bytes
      Redis.current.publish "bytes_increased:#{connector_id}", Redis.current.get("bytes:#{connector_id}")
    end
  end

end
