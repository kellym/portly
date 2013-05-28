class UserCreationService
  def initialize(user_klass = User, mailer_klass = UserMailer)
    @user_klass = user_klass
    @mailer_klass  = mailer_klass
  end

  def create(params)
    @user_klass.create(params).tap do |u|
      @mailer_klass.signup u.id if u.persisted?
    end
  end
end
