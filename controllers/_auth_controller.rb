class AuthController < SharedController

  route '/github/callback', method: ['GET', 'POST'] do
    puts env['rack.auth'].inspect
  end

end
