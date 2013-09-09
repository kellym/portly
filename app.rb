require_relative 'config/dependencies'

ROOT_PATH = File.dirname(__FILE__)
if ENV['RACK_ENV'] == 'development'
  LOG = Logger.new STDOUT
else
  LOG = Logger.new(ROOT_PATH + '/log/' + (ENV['RACK_ENV'] || 'development') + '.log', 'daily')
end
LOG.level = Logger::DEBUG

@redis_host, @redis_port = (ENV['REDIS_HOST']||'127.0.0.1:6379').split(':')
Redis.current = Redis.new(:host => @redis_host, :port => @redis_port.to_i)
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
require_relative 'config/settings'

# Set up the Stripe API Key
Stripe.api_key = App.config.stripe_secret_key

database_setup = YAML.load(File.read('config/database.yml'))
ActiveRecord::Base.establish_connection database_setup[ENV['RACK_ENV']]

Mail.defaults do
  delivery_method :smtp, {
    address:   ::App.config.mail.address,
    port:      ::App.config.mail.port,
    user_name: ::App.config.mail.user_name,
    password:  ::App.config.mail.password
  }
end

# HAML Options
Haml::Options.defaults[:ugly] = true

# Dragonfly
DRAGONFLY = Dragonfly[:images].configure_with(:imagemagick) do |c|
  c.url_format = '/media/:job'
end
DRAGONFLY.define_macro(ActiveRecord::Base, :image_accessor)

Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/mailers/*.rb'].each {|file| require file }
require_relative 'controllers/application_controller'
