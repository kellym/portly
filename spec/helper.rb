ENV['RACK_ENV'] = 'test'
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

  %x[rake db:migrate RACK_ENV=test]
  Warden.test_mode!

  def app
    @app ||= ApplicationController
  end

  def controller
    app.any_instance
  end

  def self.included(base)
    base.after do
      Warden.test_reset!
    end
  end

end


