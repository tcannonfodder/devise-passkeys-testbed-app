# frozen_string_literal: true
require_relative '../strategies/passkey_authenticatable'

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

      def devise_mailer
        Devise.mailer
      end

      # This is an internal method called every time Devise needs
      # to send a notification/mail. This can be overridden if you
      # need to customize the e-mail delivery logic. For instance,
      # if you are using a queue to deliver e-mails (active job, delayed
      # job, sidekiq, resque, etc), you must add the delivery to the queue
      # just after the transaction was committed. To achieve this,
      # you can override send_devise_notification to store the
      # deliveries until the after_commit callback is triggered.
      #
      # The following example uses Active Job's `deliver_later` :
      #
      #     class User
      #       devise :database_password_authenticatable, :confirmable
      #
      #       after_commit :send_pending_devise_notifications
      #
      #       protected
      #
      #       def send_devise_notification(notification, *args)
      #         # If the record is new or changed then delay the
      #         # delivery until the after_commit callback otherwise
      #         # send now because after_commit will not be called.
      #         # For Rails < 6 use `changed?` instead of `saved_changes?`.
      #         if new_record? || saved_changes?
      #           pending_devise_notifications << [notification, args]
      #         else
      #           render_and_send_devise_message(notification, *args)
      #         end
      #       end
      #
      #       private
      #
      #       def send_pending_devise_notifications
      #         pending_devise_notifications.each do |notification, args|
      #           render_and_send_devise_message(notification, *args)
      #         end
      #
      #         # Empty the pending notifications array because the
      #         # after_commit hook can be called multiple times which
      #         # could cause multiple emails to be sent.
      #         pending_devise_notifications.clear
      #       end
      #
      #       def pending_devise_notifications
      #         @pending_devise_notifications ||= []
      #       end
      #
      #       def render_and_send_devise_message(notification, *args)
      #         message = devise_mailer.send(notification, self, *args)
      #
      #         # Deliver later with Active Job's `deliver_later`
      #         if message.respond_to?(:deliver_later)
      #           message.deliver_later
      #         # Remove once we move to Rails 4.2+ only, as `deliver` is deprecated.
      #         elsif message.respond_to?(:deliver_now)
      #           message.deliver_now
      #         else
      #           message.deliver
      #         end
      #       end
      #
      #     end
      #
      def send_devise_notification(notification, *args)
        message = devise_mailer.send(notification, self, *args)
        # Remove once we move to Rails 4.2+ only.
        if message.respond_to?(:deliver_now)
          message.deliver_now
        else
          message.deliver
        end
      end

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