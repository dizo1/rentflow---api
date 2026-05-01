class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants do |t|
      t.references :unit, null: false, foreign_key: true, index: { unique: true }
      t.string :full_name, null: false
      t.string :phone, null: false
      t.string :email
      t.string :national_id
      t.date :move_in_date, null: false
      t.date :lease_start, null: false
      t.date :lease_end, null: false
      t.string :status, null: false, default: 'pending_move_in'
      t.string :emergency_contact

      t.timestamps
    end

    add_index :tenants, :email, unique: true
    add_index :tenants, :status
    add_index :tenants, :lease_end
  end
end
