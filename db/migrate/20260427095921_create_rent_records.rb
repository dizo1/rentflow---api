class CreateRentRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :rent_records do |t|
      t.references :unit, null: false, foreign_key: true
      t.decimal :amount_due
      t.decimal :amount_paid
      t.decimal :balance
      t.date :due_date
      t.string :status
      t.integer :month
      t.integer :year
      t.datetime :paid_at

      t.timestamps
    end
  end
end
