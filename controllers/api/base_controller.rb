class Api
  class BaseController < SharedController

    middleware << proc {
      use Rack::RestApiVersioning
    }

    def connector(id)
      Connector.where(id: id, user_id: current_user.id).first
    end

    def current_user
      @user
    end

    def current_token
      return @token if @token
      @app_request = false
      if request[:access_token]
        @token = Token.where(:user_id => current_user.id, :code => request[:access_token]).first
      elsif env['warden'].user # this means we're signed in from the app
        # include both the user_id and token_id so we can't hack it
        if request[:token_id]
          @token = Token.where(:user_id => current_user.id, :id => request[:token_id]).first
        else
          # this request came from the app
          @app_request = true
          port = Connector.where(:user_id => current_user.id, :id => request[:id]).first
          @token = port.token if port
        end
      end
    end

    def publish_action(action)
      if request[:publish] != 'false'
        Redis.current.publish("socket:#{current_token.code}", action)
        true
      else
        false
      end
    end

    before do
      @user = env['warden'].user || env['warden'].authenticate!(:scope => :api)
      # check that account is still active
      halt 403 unless @user.active?

      request.body.rewind
      body = request.body.read
      if body.length > 2
        @request_payload = JSON.parse body rescue nil
        if @request_payload
          @request_payload.each do |k,v|
            request[k.to_sym] = v
          end
        end
      end
    end

    post '/unauthenticated' do
      halt 401
    end

    after do
      response['Content-Type'] = media_type.to_s
    end

    #after status: 400 do
    #  response.body = {error: @error}.to_json if @error
    #end

    after status: 404 do
      puts '404'
      puts request.inspect
    end

    # Public: Used to return the current_user in regards to the the API
    # scope for Warden.
    #
    # Returns a User or nil.
    #def current_user
    #  @current_user ||= env['warden'].user(:scope => :api)
    #end

    # Public: Throws a 403 if the current_user doesn't have access to this
    # Connector.

    def authorize!(connector_id)
      halt 403 unless Connector.where(id: connector_id.to_i, user_id: current_user.id).exists?
    end
  end
end
