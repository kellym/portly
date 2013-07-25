require_relative '../helper.rb'

describe ApplicationController do

  include SpecHelper

  describe "GET /" do
    context 'when signed in' do
      it 'should redirect signed in users to /tunnels' do
        allow_controller_to receive(:signed_in?).and_return true
        response = get '/'
        response.status.should == 307
        response['Location'].should == '/tunnels'
      end
    end
  end

  describe "GET /reset-password" do
    it "should show the reset password form with an email field" do
      expect_controller_to receive(:render).with :'account/reset_password', anything
      response = get '/reset-password'
      puts response.inspect
      #response.body['name="user[email]"'].should be_present
    end
  end

  describe "GET /reset-password/*" do
    it "should show the reset password form with password and confirmation" do
      token = '123'
      allow(User).to receive(:where).and_return [token]
      expect_controller_to receive(:render).with :'account/reset_password', anything
      response = get '/reset-password/123'
      response.body['name="user[password]"'].should be_present
    end
  end

end
