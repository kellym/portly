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

  validates_presence_of :user_id
  before_create :generate_token
  before_create :generate_authorized_key
  before_destroy :remove_tunnels

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
  def remove_tunnels

  end


end
