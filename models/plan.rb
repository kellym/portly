class Plan < ActiveRecord::Base

  # property :id, Serial
  # property :name, String, length: 50
  # property :monthly, Decimal, precision: 12, scale: 2
  # property :yearly, Decimal, precision: 12, scale: 2
  # property :computers, Integer

  AFFILIATES = %w(changelog)

  def self.free
    @free ||= Plan.where(:reference => 'free').first
  end

  def self.basic
    @basic ||= Plan.where(:reference => 'basic').first
  end

  def self.team
    @team ||= Plan.where(:reference => 'team').first
  end

  def self.business
    @business ||= Plan.where(:reference => 'business').first
  end

  def gratis?
    %(free friends).include? reference
  end

  def free?; reference == 'free'; end
  def basic?; reference == 'basic'; end
  def team?; reference == 'team'; end
  def business?; reference == 'business'; end

  def affiliate?
    AFFILIATES.include? reference
  end

end
