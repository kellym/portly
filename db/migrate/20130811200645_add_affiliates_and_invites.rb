class AddAffiliatesAndInvites < ActiveRecord::Migration
  def change
    create_table :affiliates do |t|
      t.integer :user_id
      t.string :name
      t.string :code
      t.boolean :active, default: true
      t.integer :plan_id
      t.integer :signups, default: 0
    end
    add_index :affiliates, :code
    create_table :invites do |t|
      t.integer :user_id
      t.integer :affiliate_id
      t.string :email
      t.string :code
    end
    add_index :invites, :code
  end
end
