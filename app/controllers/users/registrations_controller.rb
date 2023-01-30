# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :require_no_authentication, only: [:new, :new_challenge, :create]
  before_action :require_email_and_passkey_label, only: [:new_challenge, :create]


  def new_challenge
    webauthn_user_id = WebAuthn.generate_user_id

    options = PasskeyAuthenticator.relying_party.options_for_registration(
      user: { id: webauthn_user_id, name: sign_up_params[:email] },
      authenticator_selection: { user_verification: "required" }
    )

    session[passkey_registration_challenge_session_key] = options.challenge

    render json: options
  end


  before_action :configure_sign_up_params, only: [:new_challenge, :create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:passkey_label])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end


  def passkey_credential
    JSON.parse(passkey_params[:passkey_credential])
  end

  def passkey_params
    params.require(:user).permit(:passkey_label, :passkey_credential)
  end

  def require_email_and_passkey_label
    if sign_up_params[:email].blank? && passkey_params[:passkey_label].blank?
      render json: {message: "Email or passkey label missing"}, status: :bad_request
    end
  end

  private

  def passkey_registration_challenge_session_key
    return "#{resource_name}_registration_passkey_challenge"
  end
end
