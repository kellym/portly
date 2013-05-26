module Middleware

  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include_middleware
  end

  module ClassMethods
    def include_middleware
      middleware << proc {
        map '/assets' do
          environment = Sprockets::Environment.new
          environment.append_path 'assets/javascripts'
          environment.append_path 'assets/stylesheets'
          environment.cache = Sprockets::Cache::FileStore.new('/tmp')
          run environment
        end
      }
    end
  end
end

module Rack
  class ActiveRecord
    def initialize(app)
      @app = app
    end

    def call(env)
      response = @app.call(env)
    ensure
      ::ActiveRecord::Base.clear_active_connections!
      response
    end
  end
end
