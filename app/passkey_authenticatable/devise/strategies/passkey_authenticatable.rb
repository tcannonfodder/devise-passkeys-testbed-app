require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class PasskeyAuthenticatable < Authenticatable
      def store?
        super && !mapping.to.skip_session_storage.include?(:params_auth)
      end

      def valid?
        credential_in_params.present?
      end

      def authenticate!
        begin
          webauthn_credential, passkey = mapping.to.passkey_authenticator.relying_party.verify_authentication(
            credential_in_params, authentication_challenge_from_warden, user_verification: true
          ) do |credential|
            mapping.to.passkey_class.to_adapter.find_first(external_id: Base64.strict_encode64(credential.raw_id))
          end

          passkey.update!(sign_count: webauthn_credential.sign_count)

          resource = passkey.send(mapping)

          if validate(resource)
            remember_me(resource)
            resource.after_passkey_authentication
            success!(resource)
            return
          end

          # In paranoid mode, fail with a generic invalid error
          Devise.paranoid ? fail(:invalid) : fail(:not_found_in_database)
        rescue WebAuthn::SignCountVerificationError => e
          fail!(:sign_count_verification_error)
        rescue WebAuthn::Error => e
          fail(:webauthn_generic_error)
        end
      end

      # Override and set to false for things like OmniAuth that technically
      # run through Authentication (user_set) very often, which would normally
      # reset CSRF data in the session
      def clean_up_csrf?
        true
      end


      private

      def credential_in_params
        raw_credential = params.dig(scope, :passkey_credential)
        return nil if raw_credential.nil?
        JSON.parse(raw_credential)
      end

      def authentication_challenge_from_warden
        session["#{mapping.name}_current_credential_challenge".to_sym]
      end
    end
  end
end

Warden::Strategies.add(:passkey_authenticatable, Devise::Strategies::PasskeyAuthenticatable)