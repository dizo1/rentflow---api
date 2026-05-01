class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :property_type
      t.string :address
      t.string :status
      t.integer :total_units

      t.timestamps
    end
  end
end
