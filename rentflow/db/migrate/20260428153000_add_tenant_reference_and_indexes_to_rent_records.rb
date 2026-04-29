class AddTenantReferenceAndIndexesToRentRecords < ActiveRecord::Migration[8.1]
  def change
    # Add tenant_id reference (nullable initially for existing records) only if it doesn't exist
    unless column_exists?(:rent_records, :tenant_id)
      add_reference :rent_records, :tenant, null: true, foreign_key: true
    end

    # Add index for tenant queries only if it doesn't exist
    add_index :rent_records, :tenant_id unless index_exists?(:rent_records, :tenant_id)

    # Add unique composite index to prevent duplicate monthly records per unit only if it doesn't exist
    add_index :rent_records, [:unit_id, :month, :year], unique: true, name: 'index_rent_records_on_unit_month_year' unless index_exists?(:rent_records, :name => 'index_rent_records_on_unit_month_year')

    # Add index for overdue detection queries (status + due_date filtering) only if it doesn't exist
    # Note: We don't know the exact name of this index, so we'll check if any index exists on these columns
    unless index_exists?(:rent_records, [:status, :due_date])
      add_index :rent_records, [:status, :due_date]
    end
  end
end