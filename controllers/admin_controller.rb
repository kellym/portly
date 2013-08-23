class AdminController < SharedController

  before do
    @user = env['warden'].user || env['warden'].authenticate!
    # check that account is still active
    halt 404 # unless @user.superadmin?
  end

  get '/' do
    @user_count = User.count
    render :'admin/index', layout: :'layouts/admin'
  end

end
