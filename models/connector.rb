class Connector < ActiveRecord::Base

  # property :id, Serial
  # property :user_id, Integer
  # property :user_host, String, length: 255
  # property :user_port, Integer
  # property :user_ip, String
  # property :path, String
  # property :token_id, Integer
  # property :connector_string, String
  # property :subdomain, String, unique: true
  # property :cname, String, unique: true
  # property :auth_type, String

  attr_accessor :publish

  belongs_to :user
  belongs_to :token
  belongs_to :page
  has_many :auths, :class_name => 'ConnectorAuth'
  has_many :bytes, :class_name => 'ConnectorByte'

  validate :http_only_if_free_account # we should be able to handle 15 minutes for TCP sockets too if we wanted
  before_save :get_server_port
  after_save :update_tunnels

  default_scope where(:deleted_at => nil)

  def domain
    self.cname.present? ? self.cname : self.full_subdomain
  end

  # Public: Provides the full subdomain
  def full_subdomain
    if self.subdomain
      if self.subdomain == ''
        "#{user.subdomain}#{App.config.suffix}"
      else
        "#{self.subdomain}-#{user.subdomain}#{App.config.suffix}"
      end
    else
      nil
    end
  end

  # Public: Provides the full subdomain
  def full_subdomain_was
    if self.subdomain_was
      if self.subdomain_was == ''
        "#{user.subdomain}#{App.config.suffix}"
      else
        "#{self.subdomain_was}-#{user.subdomain}#{App.config.suffix}"
      end
    else
      nil
    end
  end

  def http?
    socket_type == 'http'
  end

  def tcp?
    socket_type == 'tcp'
  end

  def server_host
    App.config.forwarding_server.short_host
  end

  def to_hash
    {
      id: id,
      host: user_host,
      port: user_port,
      subdomain: subdomain,
      nickname: nickname,
      socket_type: socket_type,
      server_port: server_port,
      server_host: server_host,
      cname: cname,
      auth_type: auth_type,
      path: path,
      auths: auths.map { |a| a.to_hash }
    }
  end

  # Public: Uses Redis to determine if the connector is currently online
  # or not.
  #
  # Returns a Boolean of the connected status.
  def connected?
    Redis.current.sismember('connectors_online', self.id)
  end

  # Public: Uses Redis to determine if the connector is enabled,
  # meaning the port is open and available for connecting.
  #
  # Returns a Boolean of the enabled state.
  def enabled?
    Redis.current.sismember("connectors_enabled:#{token.code}", self.id)
  end

  # Public: Opposite of enabled?
  #
  # Returns a Boolean of the disabled state
  def disabled?
    !enabled?
  end

  # Internal: Updates any currently open tunnels so routes work
  # and authentication is updated
  def update_tunnels
    Tunnel.update(self) if changed?
  end

  # Public: Generate a connection string to hand to the user.
  #
  # Returns a String
  def connection_string
    self.user_port == 80 ? user_host : "#{user_host}:#{user_port}"
  end

  # Internal: Closes all open tunnels on this connector so we don't
  # track this in nginx.
  def close_tunnels
    Tunnel.new(connector_id: self.id, user_id: self.user_id, token: self.token.code).destroy!
  end

  # Public: Gets the start time of the currently open tunnel, or nil.
  def connected_at
    if connected?
      connected_at = Redis.current.hget(Tunnel.record_key(self.full_subdomain), 'connected_at')
      connected_at ? DateTime.parse(connected_at) : nil
    else
      nil
    end
  end

  def destroy
    close_tunnels
    self.update_attribute(:deleted_at, Time.now)
  end

  def get_server_port
    if http?
      server_port = nil
    elsif server_port.nil?
      port = loop do
        socket = Socket.new(:INET, :STREAM, 0)
        socket.bind(Addrinfo.tcp('127.0.0.1', 0))
        port = socket.getsockname.unpack('snA*')[1]
        socket.close
        break port unless Redis.current.sismember('ports_in_use',port) || Connector.where(server_port: port).exists?
      end
      self.server_port = port
    end
  end

  def incoming_traffic_today
    bytes_today['in'].to_i
  end

  def outgoing_traffic_today
    bytes_today['out'].to_i
  end

  def traffic_today
    bytes_today['in'].to_i + bytes_today['out'].to_i
  end

  def bytes_today
    @bytes ||= Redis.current.hgetall("bytes:#{self.id}") rescue {'in' => 0, 'out' => 0}
  end

  def path=(val)
    val = '/' + val if val[0]!='/'
    val.gsub!(/[\/\s]*$/, '')
    super(val)
  end

  def data_this_month
    return @data_this_month if @data_this_month
    month_bytes_in = month_bytes_out = Hash[(Date.today-30.days..Date.today).zip([])]
    self.bytes.where('created_at > ?', Date.today-30.days).each do |b|
      month_bytes_in[b.created_at]  = b.bytes_in
      month_bytes_out[b.created_at] = b.bytes_out
    end
    @data_this_month = [month_bytes_in, month_bytes_out]
  end

  # Public: Get the Page that is closest tied to this connector
  def closest_page
    page || (token && token.page) || (user && user.page)
  end

  def http_only_if_free_account
    if !http? && user.plan.free?
      errors.add(:socket_type, 'not allowed for free plans')
    end
  end

end
