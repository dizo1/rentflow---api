class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.integer :plan, null: false
      t.integer :status, null: false
      t.string :reference, null: false
      t.string :payment_method
      t.datetime :paid_at

      t.timestamps
    end
    add_index :payments, :reference, unique: true
  end
end
