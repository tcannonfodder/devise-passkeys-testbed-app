# frozen_string_literal: true

module Devise
  module Models

    # PasskeyRecoverable takes care of sending an emergency passkey registration request.
    #
    # ==Options
    #
    # PasskeyRecoverable adds the following options to +devise+:
    #
    #   * +emergency_passkey_registration_class+: the class that the emergency registration requests for this model are stored in.
    #   * +emergency_passkey_registration_keys+: the keys you want to use when finding and issuing an emergency registration for an account.
    #   * +emergency_passkey_registration_within+: the time period within which the emergency registration must be reset or the token expires.
    #   * +sign_in_after_emergency_passkey_registration+: whether or not to sign in the user automatically after an emergency passkey registration.
    #
    # == Examples
    #
    #   # creates a new emergency passkey registration token and send it with instructions about how to complete the emergency registration
    #   User.find(1).send_emergency_passkey_registration_instructions
    #
    module PasskeyRecoverable
      extend ActiveSupport::Concern

      # Creates an emergency passkey registration and send reset password instructions by email.
      # Returns the token sent in the e-mail.
      def send_emergency_passkey_registration_instructions
        token = create_emergency_passkey_registration
        send_reset_password_instructions_notification(token)

        token
      end

      protected

        def create_emergency_passkey_registration
          raw, enc = Devise.token_generator.generate(self.class.emergency_passkey_registration_class, :token)

          self.class.emergency_passkey_registration_class.create(
            "#{self.class.to_s.underscore.downcase}": self,
            token: enc,
            expires_at: self.class.emergency_passkey_registration_within.from_now.utc
          )

          return raw
        end

        def send_reset_password_instructions_notification(token)
          send_devise_notification(:emergency_passkey_registration_instructions, token, {})
        end

      module ClassMethods
        # Attempt to find a user by its email. If a record is found, send new
        # password instructions to it. If user is not found, returns a new user
        # with an email not found error.
        # Attributes must contain the user's email
        def send_emergency_passkey_registration_instructions(attributes = {})
          recoverable = find_or_initialize_with_errors(emergency_passkey_registration_keys, attributes, :not_found)
          recoverable.send_emergency_passkey_registration_instructions if recoverable.persisted?
          recoverable
        end

        Devise::Models.config(self, :emergency_passkey_registration_class, :emergency_passkey_registration_keys, :emergency_passkey_registration_within , :sign_in_after_emergency_passkey_registration)
      end
    end
  end
end