class CreateEmergencyPasskeyRegistrations < ActiveRecord::Migration[7.0]
  def change
    create_table :emergency_passkey_registrations do |t|
      t.references :user, index: true
      t.string :token, index: { unique: true }
      t.timestamp :used_at

      t.timestamps
    end

    change_table :passkeys do |t|
      t.references :emergency_passkey_registration, index: true
    end
  end
end
