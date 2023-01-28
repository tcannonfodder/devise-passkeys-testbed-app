class Passkey < ApplicationRecord
  belongs_to :user
  belongs_to :emergency_passkey_registration, optional: true
end
