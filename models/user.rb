class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << (options[:message] || "is not a valid email")
    end
  end
end

class User < ActiveRecord::Base
  extend Forwardable

  GIGABYTE = 1073741824

  attr_reader :password
  attr_accessor :password_confirmation
  attr_accessor :plan_id
  image_accessor :cover_image

  validates_confirmation_of :password
  validates_length_of :password, within: 6..50, :allow_blank => :persisted?
  validates :subdomain, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, email: true

  has_many :connectors
  has_many :tokens
  belongs_to :account
  belongs_to :page
  has_one :admin_account, class_name: 'Account', :foreign_key => :admin_id
  has_one :schedule
  has_one :plan, :through => :account
  has_many :orders

  before_save :downcase_email

  def_delegators :schedule, :plan_id, :plan_id=

  # Public: Initialize this user and create account and schedule first.
  def initialize(*params)
    super
    create_account_and_schedule
  end

  # Public: Checks to see if there is a user with the specific authentication
  def self.authenticate(email, password)
    user = User.where(:email => email.downcase).first
    if user && user.valid_password?(password)
      user
    else
      nil
    end
  end

  # Public: Checks whether the password provided matches the password on file
  # or not.
  #
  # Returns a Boolean of true if the password matches, false otherwise.
  def valid_password?(password)
    return false if encrypted_password.nil? || encrypted_password == ''
    bcrypt   = ::BCrypt::Password.new(encrypted_password)
    password = ::BCrypt::Engine.hash_secret("#{password}#{App.config.authentication.pepper}", bcrypt.salt)
    User.secure_compare(password, encrypted_password)
  end

  # Public: constant-time comparison algorithm to prevent timing attacks.
  # Taken from Devise.
  #
  # Returns a Boolean.
  def self.secure_compare(a,b)
    return false if a.nil? || b.nil? || a == '' || b == '' || a.bytesize != b.bytesize
    l = a.unpack "C#{a.bytesize}"

    res = 0
    b.each_byte { |byte| res |= byte ^ l.shift }
    res == 0
  end

  # Public: Sets the password to an encrypted string that can't
  # be decoded.
  def password=(password)
    @password = password
    self.encrypted_password = User.encrypt_password(password)
  end

  # Internal: Creates the initial account and payment schedule for the
  # user.
  def create_account_and_schedule
    unless self.account
      self.build_account
      self.account.admin = self
      self.account.plan ||= @plan_id ? Plan.find(@plan_id) : Plan.basic
    end
    self.build_schedule
    self.schedule.good_until = self.schedule.trial_end = (Date.today + 14.days)
    self.schedule.plan = self.account.plan
    self.state ||= self.schedule.state
  end

  def active?
    self.state == 'active' && self.schedule.state == 'active'
  end

  # Public: Generates an encrypted password from a normal string. Uses a
  # pepper string and runs the number of stretches as defined in the config.
  #
  # Returns the encrypted password.
  def self.encrypt_password(password)
    ::BCrypt::Password.create("#{password}#{App.config.authentication.pepper}", :cost => App.config.authentication.stretches).to_s
  end

  # Internal: Makes email addresses case-insensitive by saving them as lowercase
  def downcase_email
    email.downcase! if email_changed?
  end

  # Public: Determines if this account is still in the trial period
  # Returns a Boolean.
  def trial?
    schedule.trial_end >= Date.today
  end

  # Public: Provide the full domain to the user's subdomaining routes.
  def full_domain
    @full_domain ||= "#{subdomain}#{App.config.suffix}"
  end

  def total_bytes_this_month
    @total_bytes_this_month ||= bytes_this_month.sum(:bytes_total)
  end
  alias :total_monthly_bandwidth_used :total_bytes_this_month

  def bytes_this_month
    @bytes_this_month ||= ConnectorByte.joins(:connector => :user)
      .where(users: { id: self.id })
      .where('connector_bytes.created_at > ?', billing_period_start)
  end

  def monthly_bandwidth_percent_used
    ((total_bytes_this_month.to_f / (plan.bandwidth * GIGABYTE))*100).to_i
  end

  def exceeded_monthly_bandwidth?
    total_bytes_this_month > (plan.bandwidth * GIGABYTE)
  end

  def billing_period_start
    return @billing_period_start if @billing_period_start
    today = Date.today
    day = self.created_at.day
    @billing_period_start = Date.new(today.year, day > today.day ? today.month - 1 : today.month, self.created_at.day)
  end

end
