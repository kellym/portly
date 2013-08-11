class AddFreePlan < ActiveRecord::Migration
  def up
    Plan.destroy_all
    ActiveRecord::Base.connection.execute(
        "ALTER SEQUENCE plans_id_seq RESTART WITH 1"
    )
    Plan.create(reference: 'free', name: 'Free', yearly: 0, monthly: 0, computer_limit: 1, bandwidth: 5, tunnel_limit: 1)
    Plan.create(reference: 'basic', name: 'Basic', yearly: 50, monthly: 5, computer_limit: 2, bandwidth: 10, tunnel_limit: 3)
    Plan.create(reference: 'team', name: 'Team', yearly: 100, monthly: 10, computer_limit: 10, bandwidth: 50, tunnel_limit: 15)
    Plan.create(reference: 'business', name: 'Business', yearly: 250, monthly: 25, computer_limit: 25, bandwidth: 100, tunnel_limit: 50)
    Plan.create(reference: 'changelog', name: 'The Changelog Member', yearly: 40, monthly: 4, computer_limit: 2, bandwidth: 10, tunnel_limit: 3)
    Plan.create(reference: 'friend', name: 'Free For Life', yearly: 0, monthly: 0, computer_limit: 5, bandwidth: 50, tunnel_limit: 10)
  end
  def down
  end
end
