class CreateMaintenanceLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :maintenance_logs do |t|
      t.references :unit, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.decimal :cost
      t.string :status
      t.datetime :resolved_at

      t.timestamps
    end
  end
end
