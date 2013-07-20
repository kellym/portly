require './spec/helper.rb'

describe ApplicationController do

  include SpecHelper

  describe "GET /index" do
    it 'should redirect signed in users to /tunnels' do
      #app.stub(:signed_in?).and_return true
      response = get '/'
      puts response.body.inspect
      response.status.should == 302
    end
  end

end
