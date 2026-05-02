class AddDefaultsToRentRecords < ActiveRecord::Migration[8.1]
  def change
    change_column_default :rent_records, :amount_paid, from: nil, to: 0
    change_column_default :rent_records, :balance, from: nil, to: 0
  end
end