class CreateAuthorizedKeys < ActiveRecord::Migration
  def change
    create_table :authorized_keys do |t|
      t.text :public_key
      t.text :private_key
      t.string :sha1_fingerprint
      t.timestamps
    end
    add_column :tokens, :authorized_key_id, :integer
    add_index :tokens, :authorized_key_id
  end
end
