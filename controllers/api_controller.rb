class ApiController < SharedController

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
    if request[:access_token]
      @token ||= Token.where(:user_id => current_user.id, :code => request[:access_token]).first
    elsif request[:access_id] && env['warden'].user # this means we're signed in from the app
      # include both the user_id and token_id so we can't hack it
      @token ||= Token.where(:user_id => current_user.id, :id => request[:access_id]).first
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
  end

  # Public: Generates a token for the client to use for additional requests.
  post '/authorizations' do
    match_client = request[:client_id]==App.config.client_id && request[:client_secret]==App.config.client_secret
    if !match_client
      halt 403
    elsif request[:computer_name] && request[:computer_model] && request[:uuid]
      # generate a token here for this user or return one if available
      if request[:token]
        token = Token.where(:user_id => current_user.id, :code => request[:token]).first
      end
      # now find it by uuid if it exists
      unless token
        token = Token.where(:user_id => current_user.id, :uuid => request[:uuid]).first
      end
      unless token
        token = Token.create(:user_id => current_user.id, :computer_name => request[:computer_name], :computer_model => request[:computer_model])
      end
      if current_user.auth_method.is_a?(String)
        # we used an API Key
        api_key = UserToken.where(:user_id => current_user.id, :code => current_user.auth_method).first
        if api_key
          api_key.update_attribute(:token_id, token.id)
        end
      end
      { code: token.code,
        private_key: token.authorized_key.private_key,
        suffix: current_user.full_domain,
        public_key: App.config.public_key
      }.to_json
    else
      halt 400, { error: 'missing_params' }.to_json
    end
  end

  put '/authorizations' do
    if current_token
      if current_user.computers_connected < current_user.account.plan.computer_limit
        current_token.update_attributes(allow_remote: request[:allow_remote] == 'true')
      else
        halt 400, { error: 'exceeded_limit' }.to_json
      end
    else
      halt 404
    end
  end

  get '/tokens/*/history.js' do |token_id|
    token = Token.where(:user_id => current_user.id, :id => token_id).first
    if token
      { history: [token.data_this_month[0].values, token.data_this_month[1].values] }.to_json
    else
      { history: [] }.to_json
    end
  end

  put '/tokens/*' do |token_code|
    token = Token.where(user_id: current_user.id, code: token_code).first
    if token
      attrs = {}
      attrs[:computer_name] = request[:computer_name] if request[:computer_name].present?
      attrs[:computer_model] = request[:computer_model] if request[:computer_model].present?
      attrs[:uuid] = request[:uuid] if request[:uuid].present?
      token.update_attributes(attrs)
      {suffix: current_user.full_domain}.to_json
    else
      halt 403
    end
  end

  delete '/tokens/*' do |token_code|
    if token_code == 'current'
      token_code = current_token.code
    end
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

  post '/keys' do
    token = UserToken.create(:user_id => current_user.id)
    if token
      { code: token.code }.to_json
    else
      halt 400
    end
  end

  delete '/keys/*' do |token_code|
    token = UserToken.where(user_id: current_user.id, code: token_code).first
    if token
      Redis.current.publish("socket:#{token.code}", 'signout')
      token.destroy
      {}.to_json
    else
      halt 403
    end
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
      unless publish_action "connect:#{request[:connector_id]}|#{tunnel.connection_string}|#{tunnel.tunnel_string}"
        tunnel.to_json
      end
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
      halt 200
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
    connectors = Connector.where(user_id: current_user.id, token_id: current_token.id)
    connectors.map { |c| c.to_hash }.to_json
  end

  # Public: Get a current connector for the user.
  get '/connectors/*' do |connector_id|
    authorize! connector_id
    connector = connector(connector_id)
    if connector
      if media_type.html?
        render :'tunnels/_connector.haml', locals: { c: connector, token: current_token }, layout: nil
      else
        connector.to_hash.to_json
      end
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
    if request[:connection_string] || (request[:port] && request[:host])
      parse_connection_string
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
        EventSource.publish(current_user.id, 'new_connector', id: connector.id, token_id: current_token.id)
        publish_action "create:#{connector.id}"
        response.body = {:id => connector.id}.to_json
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
    if (request[:port] && request[:host]) || request[:connection_string]
      parse_connection_string
      connector = connector(connector_id)
      if connector
        data = {
          user_port: request[:port],
          user_host: request[:host],
          token_id: current_token.id,
          subdomain: request[:subdomain],
          cname: request[:cname]
        }
        data[:auth_type] = request[:auth_type] if request[:auth_type]
        if connector.update_attributes(data)
          EventSource.publish(current_user.id, 'update', id: connector.id, token_id: connector.token_id)
          publish_action "update:#{connector.id}"
          halt 204
        else
          halt 400
        end
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
      EventSource.publish(current_user.id, 'delete', id: connector.id, token_id: connector.token_id)
      publish_action "destroy:#{connector_id}"
    else
      halt 404
    end
  end

  # Public: Creates a new page for this account
  post '/pages' do
    create_or_update_page
  end

  # Public: Updates the current page for this account
  put '/pages' do
    create_or_update_page
  end

  def create_or_update_page
    request[:page]['cover_image'] = request[:page]['cover_image'][:tempfile] if request[:page]['cover_image'].present?
    if request[:page]['token_id']
      page = Token.where(:user_id => current_user.id, :id => request[:page]['token_id']).first.page
    elsif request[:page]['connector_id']
      authorize! request[:page]['connector_id']
      page = Connector.includes(:page).find(request[:page]['connector_id']).page
    else
      page = current_user.page
    end
    if page
      if page.update_attributes(request[:page])
        '{}'
      else
        halt 400
      end
    else
      page = Page.new(request[:page])
      if request[:page][:token_id]
        page.token_id = Token.where(:user_id => current_user.id, :id => request[:page][:token_id]).first.id
      elsif request[:page][:connector_id]
        authorize! request[:page][:connector_id]
        page.connector_id = request[:page][:connector_id]
      else
        page.user_id = current_user.id
      end
      if page.save
        '{}'
      else
        halt 400
      end
    end
  end

  post '/unauthenticated' do
    halt 401
  end

  after do
    response['Content-Type'] = media_type.to_s
  end

  after status: 400 do
    response.body = {error: @error}.to_json if @error
  end

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


  # Public: Parses the connection string supplied and assigns the values to
  # :host and :request
  #
  # Returns the host, port combo.
  def parse_connection_string
    if request[:connection_string]
      if request[:connection_string].match(':')
        request[:host], request[:port] = request[:connection_string].split(':',2)
      elsif request[:connection_string].to_i.to_s == request[:connection_string]
        request[:host], request[:port] = 'localhost', request[:connection_string]
      else
        request[:host], request[:port] = request[:connection_string].present? ? request[:connection_string] : 'localhost', 80
      end
    end
  end
end
