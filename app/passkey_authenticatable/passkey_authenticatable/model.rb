# frozen_string_literal: true

module Devise
  module Models
    # Authenticatable Module, responsible for setting up the relying party used by
    # WebAuthn for creating and authenticating passkeys to validate the authenticity
    # of the user when signing in
    #
    # This module defines a `passkey_authenticator` method. This method has the
    # relying_party as a property, which will be used for WebAuthn calls
    #
    # == Options
    #
    # PasskeyAuthenticatable adds the following options to +devise+:
    #
    #   * +passkey_authenticator+: the class that wraps the `WebAuthn::RelyingParty`, and has a `relying_party` class method
    #
    #   * +passkey_class+: the class that the passkeys for this model are stored in.
    #
    #   * +send_email_changed_notification+: notify original email when it changes.
    #
    module PasskeyAuthenticatable
      extend ActiveSupport::Concern

      included do
        after_update :send_email_changed_notification, if: :send_email_changed_notification?
      end

      def initialize(*args, &block)
        @skip_email_changed_notification = false
        super
      end

      # Skips sending the email changed notification after_update
      def skip_email_changed_notification!
        @skip_email_changed_notification = true
      end

      # A callback initiated after successfully authenticating. This can be
      # used to insert your own logic that is only run after the user successfully
      # authenticates.
      #
      # Example:
      #
      #   def after_passkey_authentication
      #     self.update_attribute(:invite_code, nil)
      #   end
      #
      def after_passkey_authentication
      end

      if Devise.activerecord51?
        # Send notification to user when email changes.
        def send_email_changed_notification
          send_devise_notification(:email_changed, to: email_before_last_save)
        end
      else
        # Send notification to user when email changes.
        def send_email_changed_notification
          send_devise_notification(:email_changed, to: email_was)
        end
      end

    protected

      if Devise.activerecord51?
        def send_email_changed_notification?
          self.class.send_email_changed_notification && saved_change_to_email? && !@skip_email_changed_notification
        end
      else
        def send_email_changed_notification?
          self.class.send_email_changed_notification && email_changed? && !@skip_email_changed_notification
        end
      end

      module ClassMethods
        Devise::Models.config(self, :passkey_authenticator, :passkey_class, :send_email_changed_notification)
      end
    end
  end
end