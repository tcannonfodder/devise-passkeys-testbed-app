class AddExpiresAtToEmergencyPasskeyRegistrations < ActiveRecord::Migration[7.0]
  def change
    change_table :emergency_passkey_registrations do |t|
      t.datetime :expires_at, null: false
    end
  end
end
