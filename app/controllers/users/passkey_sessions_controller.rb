# frozen_string_literal: true

class Users::PasskeySessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  def new_challenge
    webauthn_user_id = WebAuthn.generate_user_id

    options = PasskeyAuthenticator.relying_party.options_for_authentication(
      user_verification: "required"
    )

    session[passkey_session_challenge_session_key] = options.challenge

    render json: options
  end

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
  protected

  def passkey_session_challenge_session_key
    return "#{resource_name}_current_credential_challenge"
  end
end
