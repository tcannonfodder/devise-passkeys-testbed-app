class AddWebauthnIdToUser < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.string :webauthn_id, index: { unique: true }
    end
  end
end
