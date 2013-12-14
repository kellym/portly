class Invite < ActiveRecord::Base

  belongs_to :user
  belongs_to :affiliate

  validates :affiliate_id, presence: true
  # validates :email, presence: true
  validates :email, uniqueness: { scope: :affiliate_id }, allow_blank: true

  before_create :generate_token
  before_create :assign_plan_id

  # Internal: Generates an authentication token for the affiliate to
  # access their API.
  def generate_token
    self.code = loop do
      token = SecureRandom.base64(32).tr('+/=lIO0', 'pqrsxyz')
      break token unless self.class.where(code: token).exists?
    end
  end

  # Internal: Assigns the plan id based on the Affiliate
  def assign_plan_id
    self.plan_id = self.affiliate.plan_id
  end

  # Public: Mark that this invite has been used.
  def mark_as_used_by(user)
    self.user_id = user.id
    self.save && self.affiliate.update_attribute(:signups, self.affiliate.signups + 1)
  end
end

