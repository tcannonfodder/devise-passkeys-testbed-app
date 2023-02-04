# frozen_string_literal: true

module Devise
  module Models

    # EmergencyPasskeyRegistration stores and takes care of tracking usage for emergency passkey registrations
    #
    # Note that the following class method must be defined:
    #
    #   * +devise_resource_class+: the model that these emergency registration requests are for.
    module EmergencyPasskeyRegistration
      extend ActiveSupport::Concern

      # Checks if the emergency passkey registration has not expired.
      # We do this by checking if the used_at is present, and if the current time is after the `expires_at`.
      # Returns true if the emergency_registration has not been used and is before the `expires_at`
      #
      # Example:
      def emergency_registration_period_valid?
        return false unless used_at.nil?
        return expires_at && Time.now.utc < expires_at
      end

      def mark_as_used
        self.used_at = Time.now.utc
        self.save
      end


      module ClassMethods
        # Attempt to find an emergency passkey registration by its token. If an emergency registration is
        # found, return it.
        # If an emergency registration is not found, return nil
        def with_token(token)
          emergency_passkey_registration_token = Devise.token_generator.digest(self, :token, token)
          to_adapter.find_first(token: emergency_passkey_registration_token)
        end
      end
    end
  end
end