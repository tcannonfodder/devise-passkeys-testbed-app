class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :passkey_authenticatable, :registerable, :rememberable, :passkey_recoverable, passkey_authenticator: PasskeyAuthenticator, passkey_class: Passkey, emergency_passkey_registration_class: EmergencyPasskeyRegistration, emergency_passkey_registration_keys: [:email], emergency_passkey_registration_within: 1.hour


  has_many :passkeys
  has_many :emergency_passkey_registrations
end
