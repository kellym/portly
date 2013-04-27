class AuthorizedKey < ActiveRecord::Base

  has_one :token

  before_create :generate_ssh_key
  after_commit :save_to_file, :on => :create

  # Internal: Generates the SSH keys that will be used to
  # store to the file after commit.
  def generate_ssh_key
    key = loop do
      check_key = SSHKey.generate(type: 'RSA', bits: 2048)
      break check_key unless self.class.where(sha1_fingerprint: check_key.sha1_fingerprint).exists?
    end
    self.private_key = key.private_key
    self.public_key = key.ssh_public_key
    self.sha1_fingerprint = key.sha1_fingerprint
  end

  # Internal: Save the ssh public_key to the authorized_keys file
  # so the user can access the server for tunneling.
  def save_to_file
    File.open(App.config.authorized_keys_path, 'a') do |f|
      f.puts "#{self.public_key} #{self.id}"
    end
  end

end
