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
  has_many :connectors

  validates_presence_of :user_id
  before_create :generate_token
  before_create :generate_authorized_key
  before_destroy :remove_tunnels

  scope :active, where('tokens.computer_name IS NOT NULL')

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

  def laptop?
    self.computer_model.to_s.match(/Book/)
  end

  def desktop?
    !laptop?
  end
end
