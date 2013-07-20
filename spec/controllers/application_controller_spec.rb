require_relative '../helper.rb'

describe ApplicationController do

  include SpecHelper

  describe "GET /" do
    context 'when signed in' do
      it 'should redirect signed in users to /tunnels' do
        controller.stub(:signed_in?).and_return true
        response = get '/'
        response.status.should == 307
        response['Location'].should == '/tunnels'
      end
    end
  end

end
