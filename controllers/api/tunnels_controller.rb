class Api::TunnelsController < Api::BaseController

  # Public: Set up a new tunnel connector
  #
  # connector_id - the ID of the already created connector
  #
  # Returns data with the ip and port to connect to
  post '/' do
    # require a connector_id
    halt 400, {error: 'missing_id'}.to_json unless request[:connector_id]
    authorize! request[:connector_id]

    # depending on account, must be same IP as current open connectors
    tunnel = Tunnel.new(connector_id: request[:connector_id].to_i,
                        user_id: current_user.id,
                        token: current_token.code)

    if tunnel.save
      response.status = 201
      unless publish_action "connect:#{request[:connector_id]}|#{tunnel.connection_string}|#{tunnel.tunnel_string}"
        tunnel.to_json
      end
    else
      # handle errors
      if tunnel.errors.include? :not_authorized
        halt 403
      elsif tunnel.errors.include? :already_connected
        halt 400, {error: 'already_connected'}.to_json
      elsif tunnel.errors.include? :exceeded_limit
        halt 400, {error: 'exceeded_limit'}.to_json
      else
        halt 400, {error: tunnel.errors.first.to_s}.to_json
      end
    end
  end

  # Public: Destroys an open tunnel
  #
  # connector_id - the ID of the connector to close the tunnel to
  delete '/*' do |connector_id|
    authorize! connector_id
    if Tunnel.destroy(connector_id: connector_id.to_i, user_id: current_user.id, token: current_token.code)
      publish_action "kill:#{connector_id}"
      halt 200
    else
      halt 400
    end
  end

end
