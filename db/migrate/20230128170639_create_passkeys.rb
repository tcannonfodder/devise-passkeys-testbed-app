class CreatePasskeys < ActiveRecord::Migration[7.0]
  def change
    create_table :passkeys do |t|
      t.references :user, index: true
      t.string :label
      t.string :external_id, index: { unique: true }
      t.string :public_key
      t.integer :sign_count, default: 0, null: false
      t.datetime :last_used_at

      t.timestamps
    end
  end
end
