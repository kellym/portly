class AddSubdomainToUsers < ActiveRecord::Migration
  def change
    add_column :users, :subdomain, :string, :unique => true
  end
end
