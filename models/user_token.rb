class UserToken < ActiveRecord::Base

  belongs_to :token
  belongs_to :user

  default_scope where(:deleted_at => nil)

  validates_presence_of :user_id
  before_create :generate_token

  # Internal: Generates an authentication token for the user to
  # access their data via the app.
  def generate_token
    self.code = loop do
      token = SecureRandom.base64(32).tr('+/=lIO0', 'pqrsxyz')
      break token unless self.class.where(code: token).exists?
    end
  end

end
