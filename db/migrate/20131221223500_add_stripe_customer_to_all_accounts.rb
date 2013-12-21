class AddStripeCustomerToAllAccounts < ActiveRecord::Migration
  def up
    creation_service = UserCreationService.new
    User.includes(:account).where('accounts.customer_id IS NULL').each do |u|
      creation_service.create_stripe_customer(u)
    end
  end
  def down
  end
end
