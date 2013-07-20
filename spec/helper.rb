require 'rack/test'
require './app.rb'

module RSpec
  module Mocks
    class Mock
      def marshal_load(*args)
      end
    end
  end
end

module SpecHelper
  include Rack::Test::Methods
  include Warden::Test::Helpers

  Warden.test_mode!

  def app
    @app ||= ApplicationController
  end

  def controller
    app.any_instance
  end

end


