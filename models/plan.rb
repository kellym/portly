class Plan < ActiveRecord::Base

  # property :id, Serial
  # property :name, String, length: 50
  # property :monthly, Decimal, precision: 12, scale: 2
  # property :yearly, Decimal, precision: 12, scale: 2
  # property :computers, Integer

  def self.micro
    @micro ||= Plan.where(:reference => 'micro').first
  end

  def self.team
    @team ||= Plan.where(:reference => 'team').first
  end

  def self.business
    @business ||= Plan.where(:reference => 'business').first
  end

end
