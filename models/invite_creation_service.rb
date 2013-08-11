class InviteCreationService
  def initialize(invite_klass = Invite, mailer_klass = UserMailer)
    @invite_klass = invite_klass
    @mailer_klass  = mailer_klass
  end

  def create(params)
    @invite_klass.create(params).tap do |i|
      @mailer_klass.invite i.id if i.persisted?
    end
  end
end

