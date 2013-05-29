class CreateTokenRecordsTable < ActiveRecord::Migration
  def change
    create_table :token_records do |t|
      t.integer :token_id
      t.string :ip_address
      t.datetime :online_at
      t.datetime :offline_at
    end
    add_index :token_records, :token_id
    add_index :token_records, :online_at
  end
end
