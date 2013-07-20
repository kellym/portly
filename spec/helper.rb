require 'rack/test'
require './app.rb'

module SpecHelper
  include Rack::Test::Methods

  def app
    @app ||= ApplicationController
  end

end


