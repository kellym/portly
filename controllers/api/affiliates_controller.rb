class Api::AffiliatesController < SharedController

  before do
    @affiliate = env['warden'].authenticate!(:scope => :affiliate)
    # check that account is still active
    halt 403 unless @affiliate.active?
  end

  post '/invites' do
    if request[:email]
      if request[:method] && request[:method] == 'email'
        klass = InviteCreationService.new
      else
        klass = Invite
      end
      invite = klass.create(affiliate_id: @affiliate.id,
                            email: request[:email])
      if invite.persisted?
        {code: invite.code}.to_json
      else
        halt status: 400
      end
    else
      @error = 'Email address is required'
      halt status: 400
    end
  end

end
