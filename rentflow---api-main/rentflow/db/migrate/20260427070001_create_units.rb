class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.references :property, null: false, foreign_key: true
      t.string :unit_number
      t.decimal :rent_amount
      t.decimal :deposit_amount
      t.string :occupancy_status
      t.string :tenant_name
      t.string :tenant_phone

      t.timestamps
    end
  end
end
