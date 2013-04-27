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
  has_many :auths, :class_name => 'ConnectorAuth'
  attr_accessor :publish

  after_save :update_tunnels
  before_destroy :close_tunnels

  # Public: Provides the full subdomain
  def full_subdomain
    self.subdomain ? "#{self.subdomain}#{App.config.suffix}" : nil
  end

  # Public: Provides the full subdomain
  def full_subdomain_was
    self.subdomain_was ? "#{self.subdomain_was}#{App.config.suffix}" : nil
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

  # Internal: Updates any currently open tunnels so routes work
  # and authentication is updated
  def update_tunnels
    Tunnel.update(self) if changed?
  end

  # Internal: Closes all open tunnels on this connector so we don't
  # track this in nginx.
  def close_tunnels
    Tunnel.new(connector_id: self.id, user_id: self.user_id).destroy!
  end

end
