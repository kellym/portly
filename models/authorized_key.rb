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
    unless key_exists_in_file(App.config.authorized_keys_path)
      File.open(App.config.authorized_keys_path, 'a') do |f|
        f.puts "#{self.public_key} #{self.id}"
      end
    end
    if token.user.plan.free?
      # remove it if it exists
      if key_exists_in_file(App.config.pro_authorized_keys_path)
        f = File.new(App.config.pro_authorized_keys_path, 'r+')
        f.each do |line|
          if line.chomp == "#{self.public_key} #{self.id}"
            # seek back to the beginning of the line.
            f.seek(-line.length, IO::SEEK_CUR)

            # overwrite line with spaces and add a newline char
            f.write(' ' * (line.length - 1))
            f.write("\n")
          end
        end
        f.close
      end
    elsif !key_exists_in_file(App.config.pro_authorized_keys_path)
      File.open(App.config.pro_authorized_keys_path, 'a') do |file|
        file.puts "#{self.public_key} #{self.id}"
      end
    end
  end

  def key_exists_in_file(file)
    f = File.open(file)
    f.each do line
      line.chomp!
      if line == "#{self.public_key} #{self.id}"
         return true
      end
    end
    false
  end

end
