module PasskeyReauthentication
  extend ActiveSupport::Concern

  def store_reauthentication_token_in_session
    session[passkey_reauthentication_token_key] = Devise.friendly_token(50)
  end

  def stored_reauthentication_token
    session[passkey_reauthentication_token_key]
  end

  def valid_reauthentication_token?(given_reauthentication_token:)
    Devise.secure_compare(session[passkey_reauthentication_token_key], given_reauthentication_token)
  end

  def passkey_reauthentication_token_key
    return "#{resource_name}_current_reauthentication_token"
  end
end