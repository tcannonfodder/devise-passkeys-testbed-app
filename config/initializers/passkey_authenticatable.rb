module Devise
  mattr_accessor :sign_in_after_emergency_passkey_registration
  @@sign_in_after_emergency_passkey_registration = true
end

Devise.add_module :passkey_authenticatable, route: { session: [nil, :new, :create, :destroy]}, model: "devise/models/passkey_authenticatable", strategy: true, controller: :passkey_sessions
Devise.add_module :passkey_recoverable,  controller: :emergency_passkey_registrations