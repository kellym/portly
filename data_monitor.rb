#!/usr/bin/env ruby

$stdout.sync = true
#require 'active_record'
require 'file-tail'
require 'logrotate'
require 'redis'

@redis_host, @redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
Redis.current = Redis.new(:host => @redis_host, :port => @redis_port.to_i)
filename = '/var/log/portly.bytes.log'

trap('TERM') do
  LogRotate.rotate_file(filename, {
    :count => 30,
    :gzip => true
  })
end

File::Tail::Logfile.open(filename) do |log|

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
