require 'warden'

Warden::Manager.serialize_into_session{|user| user.id }
Warden::Manager.serialize_from_session{|id| User.find(id) }

Warden::Manager.before_failure do |env,opts|
  env['REQUEST_METHOD'] = "POST"
  env['breadcrumb'] = []
end

Warden::Manager.after_authentication do |user,auth,opts|

end

Warden::Strategies.add(:password) do
  def valid?
    params['user'] && params["user"]["email"] && params["user"]["password"]
  end

  def authenticate!
    u = User.authenticate(params["user"]["email"], params["user"]["password"])
    u.nil? ? fail!("Could not log in") : success!(u)
  end
end

Warden::Strategies.add(:api_token) do
  def valid?
    params['access_token']
  end

  def authenticate!
    t = Token.where(code: params['access_token']).first
    if t
      if params['computer_name'] && params['computer_name'] != t.computer_name
        t.update(computer_name: params['computer_name'])
      end
      success!(t.user)
    else
      fail!("Could not log in")
    end
  end

  def store?
    false
  end
end

Warden::Strategies.add(:api_password) do
  def valid?
    params['user'] && params["user"]["email"] && params["user"]["password"]
  end

  def authenticate!
    u = User.authenticate(params["user"]["email"], params["user"]["password"])
    u.nil? ? fail!("Could not log in") : success!(u)
  end

  def store?
    false
  end
end

Warden::Strategies.add(:basic) do

  def auth
    @auth ||= Rack::Auth::Basic::Request.new(env)
  end

  def valid?
    auth.provided? && auth.basic? && auth.credentials
  end

  def authenticate!
    user = User.authenticate(
      auth.credentials.first,
      auth.credentials.last
    )
    user.nil? ? custom!(unauthorized) : success!(user)
  end

  def store?
    false
  end

  def unauthorized
    [
      401,
      {
        'Content-Type' => 'text/plain',
        'Content-Length' => '0',
        'WWW-Authenticate' => %(Basic realm="realm")
      },
      []
      ]
  end
end
