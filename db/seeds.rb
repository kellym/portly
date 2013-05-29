# Create the Accounts for managing the moolah.

Plan.create(name: 'Micro', reference: 'micro', monthly: 3, yearly: 30, tunnel_limit: 1, computer_limit: 1, bandwidth: 5)
Plan.create(name: 'Basic', reference: 'basic', monthly: 5, yearly: 50, tunnel_limit: 3, computer_limit: 2, bandwidth: 10)
Plan.create(name: 'Pro', reference: 'pro', monthly: 15, yearly: 150, tunnel_limit: 15, computer_limit: 10, bandwidth: 50)
Plan.create(name: 'Team', reference: 'team', monthly: 30, yearly: 300, tunnel_limit: 30, computer_limit: 20, bandwidth: 200)
Plan.create(name: 'Business', reference: 'business', monthly: 45, yearly: 450, tunnel_limit: 60, computer_limit: 60, bandwidth: 500)

Account.create(code: 'billing')
Account.create(code: 'refunds')
