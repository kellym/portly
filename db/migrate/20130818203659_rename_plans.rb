class RenamePlans < ActiveRecord::Migration
  def up
    Plan.destroy_all
    ActiveRecord::Base.connection.execute(
        "ALTER SEQUENCE plans_id_seq RESTART WITH 1"
    )
    Plan.create(reference: 'free', name: 'Free', yearly: 0, monthly: 0, computer_limit: 1, bandwidth: 5, tunnel_limit: 1)
    Plan.create(reference: 'glazed', name: 'Glazed', yearly: 49.00, monthly: 4.99, computer_limit: 2, bandwidth: 10, tunnel_limit: 2)
    Plan.create(reference: 'creme', name: 'Boston Creme', yearly: 99.00, monthly: 9.99, computer_limit: 5, bandwidth: 50, tunnel_limit: 5)
    Plan.create(reference: 'burger', name: 'Donut Burger', yearly: 199.00, monthly: 19.99, computer_limit: 10, bandwidth: 100, tunnel_limit: 10)
    Plan.create(reference: 'changelog', name: 'The Changelog Member', yearly: 39.00, monthly: 3.99, computer_limit: 2, bandwidth: 10, tunnel_limit: 2)
    Plan.create(reference: 'friend', name: 'Free For Life', yearly: 0, monthly: 0, computer_limit: 5, bandwidth: 50, tunnel_limit: 10)
  end
  def down
  end
end
