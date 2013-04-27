class AuthenticationController < Scorched::Controller

  post '/unauthenticated' do
    'not authenticated'
  end

end
