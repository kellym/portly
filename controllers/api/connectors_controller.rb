class Api::ConnectorsController < Api::BaseController

  # Public: Creates a new auth user for connecting to this Connector
  post '/*/auths' do |connector_id|
    authorize! connector_id
    if ConnectorAuth.create(connector_id: connector_id.to_i, username: request[:username], password: request[:password])
      publish_action "auths:#{connector_id}"
      halt 201
    else
      halt 400
    end
  end

  # Public: Gets the list of all the users and passwords for this Connector
  get '/*/auths' do |connector_id|
    authorize! connector_id
    auths = ConnectorAuth.where(connector_id: connector_id.to_i).all
    auths.map { |a| {:username => a.username, :password => a.password} }.to_json
  end

  # Public: Change the user name or password of a basic auth user.
  put '/*/auths/*' do |connector_id, username|
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
  put '/*/auths' do |connector_id|
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
  delete '/*/auths/*' do |connector_id, username|
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
  get '/' do
    connectors = Connector.where(user_id: current_user.id, token_id: current_token.id)
    connectors.map do |c|
      h = c.to_hash
      if current_token.version < "1.0.0"
        h.delete(:nickname)
        h.delete(:socket_type)
        h.delete(:server_port)
        h.delete(:server_host)
      end
      if current_token.version < "1.1.2"
        h.delete(:path)
      end
      h
    end.to_json
  end

  # Public: Get a current connector for the user.
  get '/*' do |connector_id|
    authorize! connector_id
    connector = connector(connector_id)
    if connector
      if media_type.html?
        render :'tunnels/_connector.haml', locals: { c: connector, token: current_token }, layout: nil
      else
        c = connector.to_hash
        if current_token.version < "1.0.0"
          c.delete(:nickname)
          c.delete(:socket_type)
          c.delete(:server_port)
          c.delete(:server_host)
        end
        if current_token.version < "1.1.2"
          c.delete(:path)
        end
        c.to_json
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
  post '/' do
    if request[:connection_string] || (request[:port] && request[:host])
      parse_connection_string
      data = {
        user_id: current_user.id,
        token_id: current_token.id,
        user_port: request[:port].to_i,
        user_host: request[:host],
        path: request[:path],
        subdomain: request[:subdomain],
        nickname: request[:nickname],
        cname: request[:cname],
        auth_type: request[:auth_type]
      }
      data[:socket_type] = request[:socket_type] if request[:socket_type]
      connector = Connector.create(data)
      if connector
        response.status = 201
        EventSource.publish(current_user.id, 'new_connector', id: connector.id, token_id: current_token.id)
        publish_action "create:#{connector.id}"
        response.body = {:id => connector.id, :server_port => connector.server_port, :server_host => connector.server_host }.to_json
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
  put '/*' do |connector_id|
    authorize! connector_id
    if (request[:port] && request[:host]) || request[:connection_string]
      parse_connection_string
      connector = connector(connector_id)
      if connector
        data = {
          user_port: request[:port],
          user_host: request[:host],
          nickname: request[:nickname],
          token_id: current_token.id,
          subdomain: request[:subdomain],
          cname: request[:cname]
        }
        data[:auth_type] = request[:auth_type] if request[:auth_type]
        data[:socket_type] = request[:socket_type] if request[:socket_type]
        data[:path] = request[:path] if request[:path]
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
  delete '/*' do |connector_id|
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
