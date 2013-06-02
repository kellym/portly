class Connector < ActiveRecord::Base

  # property :id, Serial
  # property :user_id, Integer
  # property :user_host, String, length: 255
  # property :user_port, Integer
  # property :user_ip, String
  # property :token_id, Integer
  # property :connector_string, String
  # property :subdomain, String, unique: true
  # property :cname, String, unique: true
  # property :auth_type, String

  belongs_to :user
  belongs_to :token
  has_many :auths, :class_name => 'ConnectorAuth'
  attr_accessor :publish

  after_save :update_tunnels

  default_scope where(:deleted_at => nil)

  def domain
    self.cname.present? ? self.cname : self.full_subdomain
  end

  # Public: Provides the full subdomain
  def full_subdomain
    self.subdomain ? "#{self.subdomain}.#{user.subdomain}#{App.config.suffix}" : nil
  end

  # Public: Provides the full subdomain
  def full_subdomain_was
    self.subdomain_was ? "#{self.subdomain_was}.#{user.subdomain}#{App.config.suffix}" : nil
  end

  def to_hash
    {
      id: id,
      host: user_host,
      port: user_port,
      subdomain: subdomain,
      cname: cname,
      auth_type: auth_type,
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

  def kb_traffic_today
    Redis.current.get("bytes:#{self.id}").to_f / 1024.0
  end

end
