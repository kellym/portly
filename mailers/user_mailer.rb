class UserMailer < Mailer

  def signup(user_id)
    @user = User.find(user_id)
    mail.to = @user.email
    mail.subject = 'Welcome to Portly!'
  end

end
