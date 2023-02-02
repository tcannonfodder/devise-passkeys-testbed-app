# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  include PasskeyReauthentication
  before_action :require_no_authentication, only: [:new, :new_challenge, :create]
  before_action :require_email_and_passkey_label, only: [:new_challenge, :create]
  before_action :verify_passkey_challenge, only: [:create]

  before_action :verify_reauthentication_token, only: [:update, :destroy]


  def new_challenge
    webauthn_user_id = WebAuthn.generate_user_id

    options = PasskeyAuthenticator.relying_party.options_for_registration(
      user: { id: webauthn_user_id, name: sign_up_params[:email] },
      authenticator_selection: { user_verification: "required" }
    )

    session[passkey_registration_challenge_session_key] = options.challenge

    render json: options
  end


  before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    super do |user|
      if user.persisted?
        user.passkeys.create!(
          label: passkey_params[:passkey_label],
          public_key: @webauthn_credential.public_key,
          external_id: Base64.strict_encode64(@webauthn_credential.raw_id),
          sign_count: @webauthn_credential.sign_count,
          last_used_at: Time.now.utc
        )
      end
    end
  end

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
  def configure_sign_up_params
    params[:user][:webauthn_id] = @webauthn_credential.id
    devise_parameter_sanitizer.permit(:sign_up, keys: [:webauthn_id])
  end

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

  def verify_passkey_challenge
    @webauthn_credential = PasskeyAuthenticator.relying_party.verify_registration(
      passkey_credential,
      session[passkey_registration_challenge_session_key],
      user_verification: true
    )
  end

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

  def update_resource(resource, params)
    resource.update(params)
  end

  def verify_reauthentication_token
    if !valid_reauthentication_token?(given_reauthentication_token: reauthentication_params[:reauthentication_token])
      render json: {error: "Not verified"}, status: :bad_request
    end
  end

  def reauthentication_params
    params.require(:user).permit(:reauthentication_token)
  end

  private

  def passkey_registration_challenge_session_key
    return "#{resource_name}_registration_passkey_challenge"
  end
end
