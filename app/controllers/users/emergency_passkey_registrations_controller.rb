# frozen_string_literal: true

class Users::EmergencyPasskeyRegistrationsController < DeviseController
  before_action :assert_emergency_passkey_registration_token_passed, only: [:new_challenge, :edit, :update]
  before_action :find_emergency_passkey_registration, only: [:new_challenge, :edit, :update]
  before_action :verify_passkey_challenge, only: [:update]

  attr_accessor :emergency_passkey_registration, :emergency_passkey_registration_token

  if respond_to?(:helper_method)
    helper_method(:emergency_passkey_registration, :emergency_passkey_registration_token)
  end

  def new_challenge
    options = PasskeyAuthenticator.relying_party.options_for_registration(
      user: { id: user_for_emergency_registration.webauthn_id, name: user_for_emergency_registration.email },
      exclude: user_for_emergency_registration.passkeys.pluck(:external_id),
      authenticator_selection: { user_verification: "required" }
    )

    session[emergency_passkey_registration_challenge_session_key] = options.challenge

    render json: options
  end

  # GET /resource/emergency_passkey_registrations/new
  def new
    self.resource = resource_class.new
  end

  # POST /resource/emergency_passkey_registrations
  def create
    self.resource = resource_class.send_emergency_passkey_registration_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_emergency_passkey_registration_instructions_path_for(resource_name))
    else
      respond_with(resource)
    end
  end

  # GET /resource/emergency_passkey_registration/edit?emergency_passkey_registration_token=abcdef
  def edit
    self.resource = resource_class.new
  end

  # PATCH /resource/emergency_passkey_registraton
  def update
    resource = user_for_emergency_registration

    resource.passkeys.create!(
      label: passkey_params[:label],
      public_key: @webauthn_credential.public_key,
      external_id: Base64.strict_encode64(@webauthn_credential.raw_id),
      sign_count: @webauthn_credential.sign_count,
      last_used_at: nil
    )

    yield resource if block_given?

    resource.unlock_access! if unlockable?(resource)

    if Devise.sign_in_after_emergency_passkey_registration
      flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
      set_flash_message!(:notice, flash_message)
      resource.after_passkey_authentication
      sign_in(resource_name, resource)
    else
      set_flash_message!(:notice, :updated_not_active)
    end

    respond_with resource, location: after_emergency_passkey_registration_path_for(resource)
  end

  protected

  def verify_passkey_challenge
    @webauthn_credential = PasskeyAuthenticator.relying_party.verify_registration(
      passkey_credential,
      session[emergency_passkey_registration_challenge_session_key],
      user_verification: true
    )
  end

  def passkey_credential
    JSON.parse(passkey_params[:credential])
  end

  def passkey_params
    params.require(:passkey).permit(:label, :credential)
  end

  def user_for_emergency_registration
    self.emergency_passkey_registration.user
  end

  def find_emergency_passkey_registration
    self.emergency_passkey_registration = emergency_passkey_registration_class.with_token(params[:emergency_passkey_registration_token])
    if !self.emergency_passkey_registration.emergency_registration_period_valid?
      set_flash_message(:alert, :expired_token)
      redirect_to new_session_path(resource_name)
    end
  end

  def emergency_passkey_registration_class
    resource_class.emergency_passkey_registration_class
  end

  def emergency_passkey_registration_challenge_session_key
    return "#{resource_name}_current_credential_challenge"
  end

  def after_emergency_passkey_registration_path_for(resource)
    Devise.sign_in_after_emergency_passkey_registration ? after_sign_in_path_for(resource) : new_session_path(resource_name)
  end

  # The path used after sending reset password instructions
  def after_sending_reset_password_instructions_path_for(resource_name)
    new_session_path(resource_name) if is_navigational_format?
  end

  def assert_emergency_passkey_registration_token_passed
    if params[:emergency_passkey_registration_token].blank?
      set_flash_message(:alert, :no_token)
      redirect_to new_session_path(resource_name)
    end

    self.emergency_passkey_registration_token = params[:emergency_passkey_registration_token]
  end

  # Check if proper Lockable module methods are present & unlock strategy
  # allows to unlock resource on password reset
  def unlockable?(resource)
    resource.respond_to?(:unlock_access!) &&
      resource.respond_to?(:unlock_strategy_enabled?) &&
      resource.unlock_strategy_enabled?(:email)
  end

  def translation_scope
    'devise.emergency_passkey_registrations'
  end
end
