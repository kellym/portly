class ConnectorAuth < ActiveRecord::Base

  belongs_to :connector

  def to_hash
    { username: username, password: password }
  end

end
