class Api::KeysController < Api::BaseController

  post '/' do
    token = UserToken.create(:user_id => current_user.id)
    if token
      { code: token.code }.to_json
    else
      halt 400
    end
  end

  delete '/*' do |token_code|
    token = UserToken.where(user_id: current_user.id, code: token_code).first
    if token
      Redis.current.publish("socket:#{token.code}", 'signout')
      token.destroy
      {}.to_json
    else
      halt 403
    end
  end

end
