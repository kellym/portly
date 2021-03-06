if File.exists?("#{ENV['HOME']}/.unicorn.rb")
  instance_eval(File.read("#{ENV['HOME']}/.unicorn.rb"))
  return
end

worker_processes 1
preload_app true
check_client_connection true

# Restart any workers that haven't responded in 30 seconds
timeout 30

##
# REE

# http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection
end

