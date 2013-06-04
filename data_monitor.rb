#!/usr/bin/env ruby

$stdout.sync = true
#require 'active_record'
require 'file-tail'
require 'redis'

@redis_host, @redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
Redis.current = Redis.new(:host => @redis_host, :port => @redis_port.to_i)
file_before = '/var/www/portly/shared/log/bytes.log'
#file_after = '/var/www/portly/shared/log/bytes_read.log'

trap('TERM') do
  File.open(file_before, 'w') {}
  logfile.close
  exit
end

File.open(file_before, 'a') {}
File.chmod(0777, file_before)

#logfile = File.open(file_after, 'w')

File::Tail::Logfile.open(file_before) do |log|

  log.tail do |line|
    connector_id, bytes_in, bytes_out, timestamp, content_type = line.split '|'
    # timestamp = Time.parse(timestamp) rescue Time.now
    bytes_in = bytes_in.to_i
    bytes_out = bytes_out.to_i
    Redis.current.hincr 'content_type:#{connector_id}', content_type
    if bytes_in > 0
      Redis.current.hincrby "bytes:#{connector_id}", 'in', bytes_in
    end
    if bytes_out > 0
      Redis.current.hincrby "bytes:#{connector_id}", 'out', bytes_out
    end
    if bytes_in > 0 || bytes_out > 0
      Redis.current.publish "bytes_increased", connector_id
    end
#    logfile.puts line
  end

end
