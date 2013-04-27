$stdout.sync = true
require 'rubygems'
require 'eventmachine'
require 'rack'
require 'thin'
require './app'

#run ApplicationController

EM.run {
  thin = Rack::Handler.get('thin')

  thin.run(ApplicationController, :Port => 9393) do |server|
    # You can set options on the server here, for example to set up SSL:
    #server.ssl_options = {
    #  :private_key_file => 'path/to/ssl.key',
    #  :cert_chain_file  => 'path/to/ssl.crt'
    #}
    #server.ssl = true
  end

}
