class ApiController < Scorched::Controller

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
    @token ||= Token.where(:user_id => current_user.id, :code => request[:access_token]).first
  end

  def publish_action(action)
    if request[:publish] != 'false'
      Redis.current.publish("socket:#{current_token.code}", action)
    end
  end

  before do
    @user = env['warden'].user || env['warden'].authenticate!(:scope => :api)
    # check that account is still active
    halt 403 unless @user.active?
  end

  # Public: Generates a token for the client to use for additional requests.
  post '/authorizations' do
    match_client = request[:client_id]==App.config.client_id && request[:client_secret]==App.config.client_secret
    if match_client && request[:computer_name]
      # generate a token here for this user or return one if available
      token = Token.create(:user_id => current_user.id, :computer_name => request[:computer_name])
      {code: token.code, private_key: token.authorized_key.private_key}.to_json
    end
  end

  put '/authorizations' do
    if current_token
      current_token.update_attributes(allow_remote: request[:allow_remote] == 'true')
    else
      halt 404
    end
  end

  delete '/tokens/*' do |token_code|
    token = Token.where(user_id: current_user.id, code: token_code).first
    if token && token.destroy
      halt 204
    else
      halt 403
    end
  end

  get '/token' do
    { email: current_user.email, }.to_json
  end

  # Public: Set up a new tunnel connector
  #
  # connector_id - the ID of the already created connector
  #
  # Returns data with the ip and port to connect to
  post '/tunnels' do
    # require a connector_id
    halt 400 unless request[:connector_id]
    authorize! request[:connector_id]

    # depending on account, must be same IP as current open connectors
    tunnel = Tunnel.new(connector_id: request[:connector_id].to_i,
                        user_id: current_user.id,
                        token: current_token.code)

    if tunnel.save
      response.status = 201
      publish_action "connect:#{request[:connector_id]}"
      tunnel.to_json
    else
      # handle errors
      if tunnel.errors.include? :not_authorized
        halt 403
      elsif tunnel.errors.include? :already_connected
        @error = 'already_connected'
        halt 400
      elsif tunnel.errors.include? :exceeded_limit
        @error = 'exceeded_limit'
        halt 400 #, {error: 'exceeded_limit'}.to_json
      else
        halt 400
      end
    end
  end

  # Public: Destroys an open tunnel
  #
  # connector_id - the ID of the connector to close the tunnel to
  delete '/tunnels/*' do |connector_id|
    authorize! connector_id
    if Tunnel.destroy(connector_id: connector_id.to_i, user_id: current_user.id, token: current_token.code)
      publish_action "kill:#{connector_id}"
      halt 204
    else
      halt 400
    end
  end

  # Public: Creates a new auth user for connecting to this Connector
  post '/connectors/*/auths' do |connector_id|
    authorize! connector_id
    if ConnectorAuth.create(connector_id: connector_id.to_i, username: request[:username], password: request[:password])
      publish_action "auths:#{connector_id}"
      halt 201
    else
      halt 400
    end
  end

  # Public: Gets the list of all the users and passwords for this Connector
  get '/connectors/*/auths' do |connector_id|
    authorize! connector_id
    auths = ConnectorAuth.where(connector_id: connector_id.to_i).all
    auths.map { |a| {:username => a.username, :password => a.password} }.to_json
  end

  # Public: Change the user name or password of a basic auth user.
  put '/connectors/*/auths/*' do |connector_id, username|
    authorize! connector_id
    ca = ConnectorAuth.where(connector_id: connector_id.to_i, username: username).first
    if ca
      ca.update_attributes(request.POST.select {|k,v| %w(username password).include?(k)})
      publish_action "auths:#{connector_id}"
    else
      halt 404
    end
  end

  # Public: Change all the users and password for this connector.
  put '/connectors/*/auths' do |connector_id|
    authorize! connector_id
    ConnectorAuth.where(connector_id: connector_id.to_i).destroy_all
    puts request[:auths].inspect
    auths= JSON.parse(request[:auths])
    auths['auths'].each do |auth|
      ConnectorAuth.create(connector_id: connector_id.to_i, username: auth['username'], password: auth['password'])
    end
    publish_action "auths:#{connector_id}"
  end

  # Public: Delete a user for the basic_auth of a Connector
  delete '/connectors/*/auths/*' do |connector_id, username|
    authorize! connector_id
    ca = ConnectorAuth.where(connector_id: connector_id.to_i, username: username).first
    if ca
      ca.destroy
      publish_action "auths:#{connector_id}"
    else
      halt 404
    end
  end

  # Public: Get all connectors for the current user.
  #
  # Returns a JSON list of all the current connectors.
  get '/connectors' do
    connectors = Connector.where(user_id: current_user.id)
    connectors.map { |c| c.to_hash }.to_json
  end

  # Public: Get a current connector for the user.
  get '/connectors/*' do |connector_id|
    authorize! connector_id
    connector = connector(connector_id)
    if connector
      connector.to_json
    else
      halt 403
    end
  end

  # Public: Create a new connector.
  #
  # port       - the local port the user is monitoring
  # host       - the local host on the user's machine
  # subdomain  - the subdomain to match up the connector
  # cname      - the record to use as an alias
  # auth_type  - using authentication or not
  #
  # Returns a Status code of 201 on creation, or 400/409 otherwise.
  post '/connectors' do
    if request[:port] && request[:host]
      connector = Connector.create(
        user_id: current_user.id,
        token_id: current_token.id,
        user_port: request[:port].to_i,
        user_host: request[:host],
        subdomain: request[:subdomain],
        cname: request[:cname],
        auth_type: request[:auth_type]
      )
      if connector
        response.status = 201
        response.body = {:id => connector.id}.to_json
        publish_action "create:#{connector.id}"
      else
        halt 409
      end
    else
      halt 400
    end
  end

  # Public: Update a current connector.
  #
  # port      - the local port the user is monitoring
  # host      - the local host on the user's machine
  # computer  - the computer that is connecting
  # subdomain - the subdomain to match up the connector
  # cname     - the record to use as an alias
  # auth_type - using authentication or not
  #
  # Returns a Status code of 200 on update, or 400/401.
  put '/connectors/*' do |connector_id|
    authorize! connector_id
    if request[:port] && request[:host]
      connector = connector(connector_id)
      if connector
        puts request.POST.inspect
        response.status = connector.update_attributes(
          user_port: request[:port],
          user_host: request[:host],
          token_id: current_token.id,
          subdomain: request[:subdomain],
          cname: request[:cname],
          auth_type: request[:auth_type]
        ) ? 204 : 400
        publish_action "update:#{connector.id}"
      else
        halt 403
      end
    else
      halt 400
    end
  end

  # Public: Destroy a current connector and make sure to destroy any tunnels.
  delete '/connectors/*' do |connector_id|
    authorize! connector_id
    connector = connector(connector_id.to_i)
    if connector
      connector.destroy
      publish_action "destroy:#{connector_id}"
    else
      halt 404
    end
  end

  post '/unauthenticated' do
    halt 401
  end

  after do
    response['Content-Type'] = 'application/json'
  end

  after status: 400 do
    response.body = {error: @error}.to_json if @error
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
