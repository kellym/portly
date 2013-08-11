class Affiliate < ActiveRecord::Base

  belongs_to :user
  belongs_to :plan
  before_create :generate_token

  validates :plan_id, presence: true
  validates :name, presence: true

  # Internal: Generates an authentication token for the affiliate to
  # access their API.
  def generate_token
    self.code = loop do
      token = SecureRandom.base64(32).tr('+/=lIO0', 'pqrsxyz')
      break token unless self.class.where(code: token).exists?
    end
  end
end
