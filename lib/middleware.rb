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

      middleware << proc {
        use ActiveRecord::ConnectionAdapters::ConnectionManagement
        use Rack::ActiveRecord
        use Faye::RackAdapter, :mount      => '/io',
                               :timeout    => 25
        use Rack::Session::Dalli,
          :compression => true,
          :memcache_server => 'localhost:11211',
          :expire_after => App.config.memcache.expires,
          :namespace => App.config.memcache.namespace,
          :key => '_sess'
        use Warden::Manager do |config|
          config.default_scope = :user
          config.scope_defaults :user,
            :strategies => [:password],
            :action     => 'unauthenticated'
          config.scope_defaults :api,
            :strategies => [:api_token, :api_password],
            :action     => 'api/unauthenticated'
          config.scope_defaults :basic,
            :strategies => [:basic],
            :action     => 'basic_auth'
          config.failure_app = ApplicationController
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
