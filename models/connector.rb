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

  attr_accessor :publish

  belongs_to :user
  belongs_to :token
  belongs_to :page
  has_many :auths, :class_name => 'ConnectorAuth'
  has_many :bytes, :class_name => 'ConnectorByte'

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
    page || token.page || user.page
  end
end
