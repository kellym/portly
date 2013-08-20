class UserCreationService
  def initialize(user_klass = User, mailer_klass = UserMailer)
    @user_klass = user_klass
    @mailer_klass  = mailer_klass
  end

  def create(params)
    @user_klass.create(params).tap do |u|
      if u.persisted?
        @mailer_klass.signup u.id
        u.invite.mark_as_used_by(u) if u.invite
      end
    end
  end
end
