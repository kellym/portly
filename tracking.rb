#!/usr/bin/env ruby

$stdout.sync = true
require 'active_record'
require 'redis'

redis_host, redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
Redis.current = Redis.new(:host => redis_host, :port => redis_port.to_i)
database_setup = YAML.load(File.read('config/database.yml'))
ActiveRecord::Base.establish_connection database_setup[ENV['RACK_ENV']]

puts "subscribing on #{ENV['REDIS_HOST']} to track_ip"
Thread.new do
  $stdout.sync = true
  Redis.current.psubscribe('track_ip:*') do |on|
    on.pmessage do |sub, chan, msg|
      token, ip_address, time, online_time = msg.split '|'
      r = ActiveRecord::Base.connection.execute("SELECT id FROM tokens WHERE code='#{token.gsub(/[^a-zA-Z0-9]/,'')}'")
      token_id = r.getvalue(0,0)
      if chan == 'track_ip:on'
        puts "SETTING ONLINE"
        ActiveRecord::Base.connection.execute("INSERT INTO token_records (token_id, ip_address, online_at) VALUES('#{token_id}', '#{ip_address}', '#{time}')")
      else
        puts "TURNING OFF"
        ActiveRecord::Base.connection.execute("UPDATE token_records SET offline_at = '#{time}' WHERE token_id = '#{token_id}' AND ip_address = '#{ip_address}' AND online_at = '#{online_time}'")
      end
    end
  end
end

sleep
