class Api::AuthorizationsController < Api::BaseController

  # Public: Generates a token for the client to use for additional requests.
  post '/' do
    match_client = request[:client_id]==App.config.client_id && request[:client_secret]==App.config.client_secret
    if !match_client
      halt 403
    elsif request[:computer_name] && request[:computer_model] && request[:uuid]
      # generate a token here for this user or return one if available
      if request[:token]
        token = Token.where(:user_id => current_user.id, :code => request[:token]).first
      end
      # now find it by uuid if it exists
      unless token
        token = Token.where(:user_id => current_user.id, :uuid => request[:uuid]).first
      end
      unless token
        token = Token.create(:user_id => current_user.id, :computer_name => request[:computer_name], :computer_model => request[:computer_model])
      end
      if current_user.auth_method.is_a?(String)
        # we used an API Key
        api_key = UserToken.where(:user_id => current_user.id, :code => current_user.auth_method).first
        if api_key
          api_key.update_attribute(:token_id, token.id)
        end
      end
      { code: token.code,
        private_key: token.authorized_key.private_key,
        suffix: current_user.full_domain,
        public_key: App.config.public_key,
        plan_type: current_user.plan.reference
      }.to_json
    else
      halt 400, { error: 'missing_params' }.to_json
    end
  end

  put '/' do
    if current_token
      if current_user.computers_connected < current_user.account.plan.computer_limit
        current_token.update_attributes(allow_remote: request[:allow_remote] == 'true')
      else
        halt 400, { error: 'exceeded_limit' }.to_json
      end
    else
      halt 404
    end
  end

  get '/keys' do
    if current_token
      { private_key: current_token.authorized_key.private_key,
        public_key: App.config.public_key,
      }.to_json
    else
      halt 401, { error: 'no access' }.to_json
    end
  end

end
