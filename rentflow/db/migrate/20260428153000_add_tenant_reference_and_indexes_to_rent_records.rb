class AddTenantReferenceAndIndexesToRentRecords < ActiveRecord::Migration[8.1]
  def change
    # Add tenant_id reference (nullable initially for existing records)
    add_reference :rent_records, :tenant, null: true, foreign_key: true

    # Add index for tenant queries
    add_index :rent_records, :tenant_id

    # Add unique composite index to prevent duplicate monthly records per unit
    add_index :rent_records, [:unit_id, :month, :year], unique: true, name: 'index_rent_records_on_unit_month_year'

    # Add index for overdue detection queries (status + due_date filtering)
    add_index :rent_records, [:status, :due_date]
  end
end
