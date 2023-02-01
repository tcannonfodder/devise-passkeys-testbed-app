class Users::PasskeysController < DeviseController
  include PasskeyReauthentication

  before_action :authenticate_user!
  before_action :find_passkey, only: [:new_destroy_challenge, :destroy]
  before_action :prepare_params, only: [:destroy]

  before_action :verify_passkey_challenge, only: [:create]
  before_action :verify_reauthentication_token, only: [:create, :destroy]

  def new_create_challenge
    webauthn_user_id = WebAuthn.generate_user_id

    options = PasskeyAuthenticator.relying_party.options_for_registration(
      user: { id: current_user.webauthn_id, name: current_user.email },
      authenticator_selection: { user_verification: "required" }
    )

    session[passkey_creation_challenge_session_key] = options.challenge

    render json: options
  end

  def create
    current_user.passkeys.create!(
      label: passkey_params[:label],
      public_key: @webauthn_credential.public_key,
      external_id: Base64.strict_encode64(@webauthn_credential.raw_id),
      sign_count: @webauthn_credential.sign_count,
      last_used_at: nil
    )

    redirect_to root_path
  end

  def new_destroy_challenge
    allowed_passkeys = (current_user.passkeys - @passkey)

    options = PasskeyAuthenticator.relying_party.options_for_authentication(
      allow: allowed_passkeys.pluck(:external_id),
      exclude: [@passkey.external_id],
      user_verification: "required"
    )

    session[passkey_reauthentication_challenge_session_key] = options.challenge

    render json: options
  end

  def destroy
    @passkey.destroy
    redirect_to root_path
  end

  protected

  def verify_passkey_challenge
    @webauthn_credential = PasskeyAuthenticator.relying_party.verify_registration(
      passkey_credential,
      session[passkey_creation_challenge_session_key],
      user_verification: true
    )
  end

  def passkey_credential
    JSON.parse(passkey_params[:credential])
  end

  def passkey_params
    params.require(:passkey).permit(:label, :credential)
  end

  def find_passkey
    @passkey = current_user.passkeys.find(params[:id])
  end

  def verify_reauthentication_token
    if !valid_reauthentication_token?(given_reauthentication_token: reauthentication_params[:reauthentication_token])
      render json: {error: "Not verified"}, status: :bad_request
    end
  end

  def reauthentication_params
    params.require(:passkey).permit(:reauthentication_token)
  end

  def passkey_creation_challenge_session_key
    return "#{resource_name}_passkey_creation_challenge"
  end

  def passkey_reauthentication_challenge_session_key
    return "#{resource_name}_current_reauthentication_challenge"
  end
end
