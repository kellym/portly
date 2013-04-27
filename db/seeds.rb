# Create the Accounts for managing the moolah.

Plan.create(name: 'Basic', reference: 'basic', monthly: 5, yearly: 50, user_limit: 1, computer_limit: 2)
Plan.create(name: 'Team', reference: 'team', monthly: 15, yearly: 150, user_limit: 10, computer_limit: 20)
Plan.create(name: 'Business', reference: 'business', monthly: 30, yearly: 300, user_limit: 25, computer_limit: 50)

Account.create(code: 'billing')
Account.create(code: 'refunds')
