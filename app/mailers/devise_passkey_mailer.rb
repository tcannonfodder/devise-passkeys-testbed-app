class DevisePasskeyMailer < Devise::Mailer
  def emergency_passkey_registration_instructions(record, token, opts = {})
    @token = token
    devise_mail(record, :emergency_passkey_registration_instructions, opts)
  end
end
