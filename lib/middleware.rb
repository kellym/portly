module Middleware

  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include_middleware
  end

  module ClassMethods
    def include_middleware
      middleware << proc {

        use ActiveRecord::ConnectionAdapters::ConnectionManagement
        use Rack::ActiveRecord
        use Rack::Session::Dalli,
          :compression => true,
          :memcache_server => 'localhost:11211',
          :expire_after => ::App.config.memcache.expires,
          :namespace => ::App.config.memcache.namespace,
          :key => '_sess',
          :secure => ::App.config.memcache.secure
        use Warden::Manager do |config|
          config.default_scope = :user
          config.scope_defaults :user,
            :strategies => [:password],
            :action     => 'unauthenticated'
          config.scope_defaults :api,
            :strategies => [:api_token, :api_password, :password],
            :action     => 'api/unauthenticated'
          config.scope_defaults :affiliate,
            :strategies => [:affiliate],
            :action     => 'unauthenticated'
          config.scope_defaults :basic,
            :strategies => [:basic],
            :action     => 'basic_auth'
          config.failure_app = ApplicationController
        end
        use Rack::CommonLogger
        use OmniAuth::Builder do
          provider :github, ::App.config.github_key, ::App.config.github_secret
        end


        # Airbrake
        if ENV['RACK_ENV'] == 'production'
          Airbrake.configure do |config|
            config.api_key = 'e3008a5af646469d059e3cd9f5d85ac7'
          end
          use Airbrake::Rack
        end

        # Dragonfly
        use Rack::Cache,
          :verbose     => true,
          :metastore   => URI.encode("file:#{::App.config.tmp_path}/cache/meta"),
          :entitystore => URI.encode("file:#{::App.config.tmp_path}/cache/body")

        use Dragonfly::Middleware, :images


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
