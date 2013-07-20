require_relative '../helper.rb'

describe ApiController do

  include SpecHelper

  def controller
    ApiController.any_instance
  end

  describe 'setup' do
    it 'should require authentication' do
      response = get '/api/token'
      response.status.should == 401
    end
    it 'should return a 403 when the user is inactive' do
      @user = double(:user).as_null_object
      @user.should_receive(:active?).and_return false
      login_as(@user, :scope => :api)
      response = get '/api/token'
      response.status.should == 403
    end
  end

  describe 'routes' do
    before do
      @user = double(:user).as_null_object
      login_as(@user, :scope => :api)
    end

    describe "GET /api/token" do
      it "should return the current user's email address" do
        controller.should_receive(:current_user).and_return @user
        @user.should_receive(:email)
        get '/api/token'
      end
    end

    describe 'POST /authorizations' do
      it 'should require matching the app id and secret to create a token' do
        response = post '/api/authorizations'
        response.status.should == 403

        response = post '/api/authorizations', client_id: App.config.client_id, client_secret: App.config.client_secret
        response.status.should_not == 403
      end
    end
  end

end

