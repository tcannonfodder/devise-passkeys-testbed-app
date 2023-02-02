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
          raw, enc = Devise.token_generator.generate(self.class.emergency_passkey_registration_class, :emergency_passkey_registration)

          self.class.emergency_passkey_registration_class.create(
            "#{self.class.to_s.underscore.downcase}": self,
            token: enc,
            expires_at: self.class.emergency_passkey_registration_within.from_now.utc
          )
        end

        def send_reset_password_instructions_notification(token)
          send_devise_notification(:emergency_passkey_registration_instructions, token, {})
        end

      module ClassMethods
        # Attempt to find a user by password reset token. If a user is found, return it
        # If a user is not found, return nil
        def with_reset_password_token(token)
          reset_password_token = Devise.token_generator.digest(self, :reset_password_token, token)
          to_adapter.find_first(reset_password_token: reset_password_token)
        end

        # Attempt to find a user by its email. If a record is found, send new
        # password instructions to it. If user is not found, returns a new user
        # with an email not found error.
        # Attributes must contain the user's email
        def send_reset_password_instructions(attributes = {})
          recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
          recoverable.send_reset_password_instructions if recoverable.persisted?
          recoverable
        end

        # Attempt to find a user by its reset_password_token to reset its
        # password. If a user is found and token is still valid, reset its password and automatically
        # try saving the record. If not user is found, returns a new user
        # containing an error in reset_password_token attribute.
        # Attributes must contain reset_password_token, password and confirmation
        def reset_password_by_token(attributes = {})
          original_token       = attributes[:reset_password_token]
          reset_password_token = Devise.token_generator.digest(self, :reset_password_token, original_token)

          recoverable = find_or_initialize_with_error_by(:reset_password_token, reset_password_token)

          if recoverable.persisted?
            if recoverable.reset_password_period_valid?
              recoverable.reset_password(attributes[:password], attributes[:password_confirmation])
            else
              recoverable.errors.add(:reset_password_token, :expired)
            end
          end

          recoverable.reset_password_token = original_token if recoverable.reset_password_token.present?
          recoverable
        end

        Devise::Models.config(self, :emergency_passkey_registration_class, :sign_in_after_emergency_passkey_registration, :sign_in_after_reset_password)
      end
    end
  end
end