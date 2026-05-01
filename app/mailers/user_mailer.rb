class UserMailer < ApplicationMailer
  def password_reset(user)
    @user = user
    @reset_url = "https://rentflowz.lovable.app/reset-password?token=#{user.password_reset_token}"
    mail(
      to: @user.email,
      from: 'onboarding@resend.dev',
      subject: 'Reset your Rentflow password'
    )
  end
end