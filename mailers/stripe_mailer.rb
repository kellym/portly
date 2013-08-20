class StripeMailer < Mailer

  def charge_succeeded(user_id)
    @user = User.find(user_id)
    mail.to = @user.email
    mail.subject = 'Your card has been charged'
  end

end
