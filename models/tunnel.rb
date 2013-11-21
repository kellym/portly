class Tunnel

  attr_accessor :connector_id, :user_id, :token, :publish, :port

  attr_reader :errors

  def initialize(opts={})
    opts.each { |k,v| instance_variable_set("@#{k}",v) }
    @errors = []
  end

  # Public: Saves the newly created tunnel to Redis to become a live connector.
  #
  # Returns a Boolean of whether the connector could be created or not.
  def save
    if valid?
      @port = get_open_port
      if connector.http?
        address_keys.each do |key|
          Redis.current.hmset key, 'port', @port,
                                   'auth', (connector.auth_type == 'basic'),
                                   'connector_id', @connector_id,
                                   'host', "#{connector.user_host}:#{connector.user_port}",
                                   'token', @token,
                                   'connected_at', DateTime.now,
                                   'original_port', connector.user_port,
                                   'folder', connector.path
        end
      elsif connector.tcp?
        #pid = fork { exec "socat TCP-LISTEN:#{@port},fork TCP:#{App.config.tcp_ip}:#{@port}" }
        Redis.current.hmset "raw:#{connector.id}", 'port', @port #, 'pid', pid
      end
      EventSource.publish(connector.user_id, 'connect', @connector_id)

      Redis.current.sadd('ports_in_use',port)
      Redis.current.sadd "watching:#{@token}", @connector_id
      if connector.user.plan.free?
        Redis.current.sadd 'free_plan', @token
      end
      Redis.current.hincrby(active_key, @token, 1)
      Redis.current.sadd('connectors_online',"#{@connector_id}")
      #if @publish
      #  Redis.current.publish("socket:#{@token}", "connect:#{@connector_id}|#{connection_string}|#{tunnel_string}")
      #end
      true
    else
      false
    end
  end

  def self.update(connector)
    tunnel = Tunnel.new(connector: connector)
    return unless tunnel.online?

    # if the port changed, the app can reconnect
    #if connector.user_port_changed?
    #  return
    #end

    if connector.path_changed?
      tunnel.address_keys.each do |key|
        Redis.current.hset key, 'folder', connector.path
      end
    end

    if connector.auth_type_changed?
      tunnel.address_keys.each do |key|
        Redis.current.hset key, 'auth', (connector.auth_type == 'basic')
      end
    end

    if connector.user_host_changed? || connector.user_port_changed?
      puts 'host or port changed'
      tunnel.address_keys.each do |key|
        Redis.current.hset key, 'host', "#{connector.user_host}:#{connector.user_port}"
      end
    end

    tunnel_data = Redis.current.hgetall Tunnel.record_key(connector.full_subdomain_was)
    if tunnel_data.blank?
      tunnel_data = Redis.current.hgetall Tunnel.record_key(connector.cname_was)
    end

    if connector.cname_changed?
      unless tunnel_data.blank?
        Redis.current.hmset Tunnel.record_key(connector.cname), *tunnel_data
      end
      Redis.current.del Tunnel.record_key(connector.cname_was)
    end
    if connector.subdomain_changed?
      unless tunnel_data.blank?
        Redis.current.hmset Tunnel.record_key(connector.full_subdomain), *tunnel_data
      end
      Redis.current.del Tunnel.record_key(connector.full_subdomain_was)
    end
  end

  def online?
    Redis.current.sismember('connectors_online', connector.id)
  end
  alias :connected? :online?

  def to_json
    { connection_string: connection_string,
      tunnel_string: tunnel_string }.to_json
  end

  def connection_string
    if connector.user.plan.free? || connector.http?
      user = App.config.forwarding_server.user
    elsif connector.tcp?
      user = App.config.forwarding_server.tcp_user
    end

    @connection_string ||= [user,App.config.forwarding_server.host].join '@'
  end

  def tunnel_string
    @tunnel_string ||= "#{App.config.forwarding_server.localhost}:#{@port}"
  end

  # Public: Closes an open tunnel by passing in the connector_id and user_id
  def self.destroy(opts={})
    Tunnel.new(opts).destroy
  end

  # Public: Closes the current tunnel if it's active, removing the Redis keys
  # and updating the count of IPs on this account.
  def destroy
    (@errors << :not_authorized) and return false unless authorized?
    destroy!
  end

  # Public: Closes the current tunnel without needing the authentication
  # token if the user is removing the connector.
  def destroy!
    if connector.http?
      port = nil
      address_keys.each do |key|
        port ||= Redis.current.hget key, 'port'
        Redis.current.del key
      end
    elsif connector.tcp?
      port = connector.server_port
      #pid = Redis.current.hget("raw:#{connector.id}", 'pid').to_i
      #if pid > 0
      #  begin
      #    Process.getpgid(pid)
      #    Process.kill("TERM", pid)
      #    Process.wait(pid)
      #  rescue
      #    # if it fails to kill it, we'll clean it up later?
      #  end
      #end
      Redis.current.del "raw:#{connector.id}"
    end
    if port
      EventSource.publish(connector.user_id, 'disconnect', @connector_id)
      Redis.current.srem('ports_in_use', port) if connector.http?
    end
    Redis.current.srem('connectors_online',"#{@connector_id}")
    Redis.current.srem "watching:#{@token}", @connector_id
    #if @publish
    #  Redis.current.publish("socket:#{@token}","kill:#{@connector_id}")
    #end
    if Redis.current.hget(active_key, @token).to_i <= 1
      Redis.current.hdel(active_key, @token)
    else
      Redis.current.hincrby(active_key, @token, -1)
    end
  end

  # Public: Determines if the current tunnel is valid to create.
  #
  # Returns a Boolean of whether it is valid or not.
  def valid?
    if connector.http?
      required_values? && authorized? && socket_online? && within_account_limit? && address_available?
    elsif connector.tcp?
      required_values? && authorized? && socket_online? && within_account_limit? && !port_in_use?
    end
  end

  # Internal: Finds the connector which this tunnel will use to connect to.
  # If the user isn't authorized, it will return nil.
  #
  # Returns a Connector or nil.
  def connector
    @connector ||= Connector.where(id: @connector_id, user_id: @user_id).first
  end

  # Internal: Determines if the port is already in use if it's a TCP socket
  #
  # Returns a Boolean.
  def port_in_use?
    Redis.current.exists "raw:#{connector.id}"
  end

  # Internal: Determines if the socket is online before we try to connect.
  #
  # Returns a Boolean of if the socket is online or not.
  def socket_online?
    if Redis.current.sismember 'sockets_online', @token
      true
    else
      @errors << :socket_offline
      false
    end
  end

  # Internal: Determines if all the required values were provided.
  #
  # Returns a Boolean of whether all the values are present or not
  def required_values?
    @connector_id && @user_id && @token
  end

  # Internal: Determines if the current user can use this connector.
  #
  # Returns a Boolean of if the user is authorized or not.
  def authorized?
    if connector
      true
    else
      @errors << :not_authorized
      false
    end
  end

  # Internal: Gets an available port on the system to link up with this
  # tunnel.
  #
  # Returns an Integer of an available port.
  def get_open_port
    if connector.http?
      port = loop do
        @socket = Socket.new(:INET, :STREAM, 0)
        @socket.bind(Addrinfo.tcp('127.0.0.1', 0))
        port = @socket.getsockname.unpack('snA*')[1]
        @socket.close
        break port unless Redis.current.sismember('ports_in_use',port) || Connector.where(server_port: port).exists?
      end
      port
    else
      connector.server_port
    end
  end

  # Internal: Provides the key in Redis used to monitor open connectors.
  #
  # Returns a String of the user's current active key.
  def active_key
    @active_key ||= "#@user_id:active"
  end

  # Internal: Provides the two possible keys that may be used for this
  # tunnel in Redis.
  #
  # Returns an Array of either one or two keys.
  def address_keys
    return @address_keys if @address_keys
    @address_keys = [
      Tunnel.record_key(connector.full_subdomain),
      Tunnel.record_key(connector.cname),
    ].compact
  end

  # Public: The key for this connector record value
  def self.record_key(record_value)
    record_value.present? ? "tunnel:#{record_value}" : nil
  end

  # Internal: Determines if the tunnel can be created because it is either
  # the same IP as open connectors, is the first open connector, or the
  # account supports multiple tokens at once.
  #
  # Returns a Boolean of the status of the account.
  def within_account_limit?
    account = User.where(id: @user_id).includes(:account).first.account
    if account
      computer_count = Redis.current.hlen(active_key).to_i
      tunnel_count = Redis.current.hvals(active_key).map { |s| s.to_i }.sum
      if (account.plan.computer_limit > computer_count) && (account.plan.tunnel_limit > tunnel_count)
        return true
      else
        if Redis.current.hexists(active_key, @token) && (account.plan.tunnel_limit > tunnel_count)
          return true
        else
          @errors << :exceeded_limit
          return false
        end
      end
    else
      return false
    end
  end

  # Internal: Determines if there is already an open connector on the
  # same domain and/or subdomain
  #
  # Returns a Boolean of false if there is already a connector, true otherwise.
  def address_available?
    address_keys.each do |key|
      if Redis.current.exists key
        @errors << :already_connected
        return false
      end
    end
    true
  end
end
