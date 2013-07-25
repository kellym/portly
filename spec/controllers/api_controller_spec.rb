require_relative '../helper.rb'

describe ApiController do

  include SpecHelper

  def controller
    ApiController
  end

  describe 'setup' do
    it 'should require authentication' do
      response = get '/api/token'
      response.status.should == 401
    end
    it 'should return a 403 when the user is inactive' do
      @user = double(:user).as_null_object
      expect(@user).to receive(:active?).and_return false
      login_as(@user, :scope => :api)
      response = get '/api/token'
      response.status.should == 403
    end
  end

  describe 'routes' do
    before do
      @user = double(:user).as_null_object
      allow(@user).to receive(:id).and_return 1
      login_as(@user, :scope => :api)
    end

    describe "GET /api/token" do
      it "should return the current user's email address" do
        expect_controller_to receive(:current_user).and_return @user
        expect(@user).to receive(:email)
        get '/api/token'
      end
    end

    describe 'POST /authorizations' do
      let(:params) do
        {client_id: App.config.client_id, client_secret: App.config.client_secret}
      end
      it 'should require matching the app id and secret to create a token' do
        response = post '/api/authorizations'
        response.status.should == 403

        response = post '/api/authorizations', params
        response.status.should_not == 403
      end
      it 'should return an error of missing_params without computer name, model, and uuid' do
        response = post '/api/authorizations', params
        response.status.should == 400
        response.body['missing_params'].should be_present
      end
      context 'when all params are present' do
        let(:valid_params) { params.merge({ computer_name: 'Charles', computer_model: 'Macaroni', uuid: '123456' }) }
        it 'should return a status of 200' do
          response = post '/api/authorizations', valid_params
          response.status.should == 200
        end
        it 'should try to find a token if passed in' do
          code = '12345'
          tokens = double(:token).as_null_object
          expect(Token).to receive(:where).with(:user_id => @user.id, :code => code).and_return tokens

          post '/api/authorizations', valid_params.merge(token: code)
        end
        it 'should try to find the token by UUID if no token code' do
          tokens = double(:token).as_null_object
          expect(Token).to receive(:where).with(:user_id => @user.id, :uuid => valid_params[:uuid]).and_return tokens

          post '/api/authorizations', valid_params
        end
        it 'should link a token with a user token if a user token was used' do
          api_key = double(:api_key)
          allow(@user).to receive(:auth_method).and_return 'string'
          allow(UserToken).to receive(:where).and_return([api_key])
          expect(api_key).to receive(:update_attribute).with(:token_id, anything)
          post '/api/authorizations', valid_params
        end
      end
    end

    describe 'PUT /authorizations' do
      context 'without a valid token' do
        it 'should return a 404' do
          response = put '/api/authorizations'
          response.status.should == 404
        end
      end
    end
  end

end

