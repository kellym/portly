class AuthController < Scorched::Controller


  post '/unauthenticated' do
    [401, {'WWW-Authenticate' => 'Basic realm="Restricted"'}, 'test']
  end

end
