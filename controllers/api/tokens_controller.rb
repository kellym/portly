class Api::TokensController < Api::BaseController

  get '/*' do |token_id|
    token = Token.where(user_id: current_user.id, id: token_id).first
    if token
      token.to_hash.to_json
    else
      halt 403
    end
  end

  get '/*/history.js' do |token_id|
    token = Token.where(:user_id => current_user.id, :id => token_id).first
    if token
      { history: [token.data_this_month[0].values, token.data_this_month[1].values] }.to_json
    else
      { history: [] }.to_json
    end
  end

  put '/*' do |token_code|
    token = Token.where(user_id: current_user.id, code: token_code).first
    if token
      attrs = {}
      attrs[:computer_name] = request[:computer_name] if request[:computer_name].present?
      attrs[:computer_model] = request[:computer_model] if request[:computer_model].present?
      attrs[:uuid] = request[:uuid] if request[:uuid].present?
      attrs[:version] = request[:version] if request[:version].present?
      token.update_attributes(attrs)
      {suffix: current_user.full_domain, plan_type: current_user.plan.name}.to_json
    else
      halt 403
    end
  end

  delete '/*' do |token_id|
    if token_id == 'current'
      token_id = current_token.id if current_token
    end
    token = Token.where(user_id: current_user.id, id: token_id).first
    if token && token.destroy
      halt 204
    else
      halt 403
    end
  end

  get '/current' do
    { email: current_user.email, }.to_json
  end

end
