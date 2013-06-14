class Token < ActiveRecord::Base

  # property :id, Serial
  # property :user_id, Integer
  # property :computer_name, String, length: 255
  # property :code, String
  # property :expires_at, DateTime
  # property :created_at, DateTime
  # property :updated_at, DateTime

  belongs_to :user
  belongs_to :authorized_key
  belongs_to :page
  has_many :connectors
  has_many :records, class_name: 'TokenRecord'

  validates_presence_of :user_id
  before_create :generate_token
  before_create :generate_authorized_key

  default_scope where(:deleted_at => nil)
  scope :active, where('tokens.computer_name IS NOT NULL AND tokens.deleted_at IS NULL')

  # Internal: Generates an authentication token for the user to
  # access their data via the app.
  def generate_token
    self.code = loop do
      token = SecureRandom.base64(32).tr('+/=lIO0', 'pqrsxyz')
      break token unless self.class.where(code: token).exists?
    end
  end

  # Internal: Generates an SSH key to pass back to the user
  # to access the server.
  def generate_authorized_key
    self.create_authorized_key
  end

  # Internal: Remove all the active tunnels for this
  # token so we don't end up with stagnant connections.
  def disconnect
    puts "DELETING (connectors_enabled:#{code}) "
    connectors.map(&:close_tunnels)
    Redis.current.del("connectors_enabled:#{code}")
  end

  def online?
    Redis.current.sismember 'sockets_online', self.code
  end
  alias :connected? :online?

  # Public: Returns the IP address of the currently online socket.
  def ip_address
    return @ip_address if @ip_address
    if online?
      record = self.records.order(:online_at).last
      @ip_address = record ? record.ip_address : nil
    else
      nil
    end
  end

  def laptop?
    self.computer_model.to_s.match(/Book/)
  end

  def desktop?
    !laptop?
  end

  def destroy
    #remove_tunnels
    self.update_attribute(:deleted_at, Time.now)
  end

  def data_this_month
    return @data_this_month if @data_this_month
    month_bytes_in  = Hash[(Date.today-30.days..Date.today).zip([])]
    month_bytes_out = Hash[(Date.today-30.days..Date.today).zip([])]
    ConnectorByte.where(:connector_id => self.connectors.pluck(:id)).where('created_at > ?', Date.today-30.days).each do |b|
      month_bytes_in[b.created_at]  = b.bytes_in
      month_bytes_out[b.created_at] = b.bytes_out
    end
    @data_this_month = [month_bytes_in, month_bytes_out]
  end

  def bytes_this_month
    return @bytes_this_month if @bytes_this_month
    bytes = ConnectorByte.joins(:connector => :user)
      .where(users: { id: self.user_id })
      .where('connector_bytes.created_at > ?', self.user.billing_period_start).all
    @bytes_this_month = { in: bytes.sum { |r| r.bytes_in }, out: bytes.sum { |r| r.bytes_out } }
  end

end
