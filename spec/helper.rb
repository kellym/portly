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
    app
  end

  def expect_controller_to(*args)
    expect_any_instance_of(controller).to(*args)
  end

  def allow_controller_to(*args)
    allow_any_instance_of(controller).to(*args)
  end

  def self.included(base)
    base.after do
      Warden.test_reset!
    end
  end

end


