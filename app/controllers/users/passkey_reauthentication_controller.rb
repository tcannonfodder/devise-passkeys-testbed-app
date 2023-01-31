# frozen_string_literal: true

class Users::PasskeyReauthenticationController < DeviseController
  include PasskeyReauthentication

  before_action :authenticate_user!

  before_action :prepare_params, only: [:reauthenticate]

  def new_challenge
    options = PasskeyAuthenticator.relying_party.options_for_authentication(
      user_verification: "required"
    )

    session[passkey_reauthentication_challenge_session_key] = options.challenge

    render json: options
  end

  def reauthenticate
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource, event: :passkey_reauthentication)
    yield resource if block_given?

    store_reauthentication_token_in_session

    render json: {reauthentication_token: stored_reauthentication_token}
  end

  protected

  def prepare_params
    params[resource_name] = {
      passkey_credential: params[:passkey_credential]
    }
  end

  def auth_options
    { scope: resource_name, recall: root_path }
  end

  def passkey_reauthentication_challenge_session_key
    return "#{resource_name}_current_reauthentication_challenge"
  end
end