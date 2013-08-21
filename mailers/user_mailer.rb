class UserMailer < Mailer

  def signup(user_id)
    @user = User.find(user_id)
    mail.to = @user.email
    mail.subject = 'Welcome to Portly!'
  end

  def reset_password(user_id)
    @user = User.find(user_id)
    mail.to = @user.email
    mail.subject = 'Portly Password Reset'
  end

  def exceeded_bandwidth(user_id)
    @user = User.find(user_id)
    mail.to = @user.email
    mail.subject = "Oops! You've exceeded your monthly bandwidth."
  end

  def invite(invite_id)
    @invite = Invite.find(invite_id)
    mail.to = @invite.email
    mail.subject = "You've been invited to Portly!"
  end

  def news_from_portly(user_id, content)
    @user = User.find(user_id)
    @content = content
    mail.to = @user.email
    mail.subject = 'News from Portly!'
  end

end
