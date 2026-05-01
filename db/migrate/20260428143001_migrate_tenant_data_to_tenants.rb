class MigrateTenantDataToTenants < ActiveRecord::Migration[8.1]
  def up
    # Only migrate data if the old columns exist
    if column_exists?(:units, :tenant_name) && column_exists?(:units, :tenant_phone)
      Unit.find_each do |unit|
        next if unit.tenant_name.blank? && unit.tenant_phone.blank?

        # Use current date as default lease dates for existing records
        default_date = Date.current
        tenant = Tenant.create!(
          unit: unit,
          full_name: unit.tenant_name,
          phone: unit.tenant_phone,
          email: nil,
          national_id: nil,
          move_in_date: default_date,
          lease_start: default_date,
          lease_end: 1.year.from_now.to_date,
          status: 'active',
          emergency_contact: nil
        )
      end
    end

    # Remove old columns if they exist
    remove_column :units, :tenant_name, :string if column_exists?(:units, :tenant_name)
    remove_column :units, :tenant_phone, :string if column_exists?(:units, :tenant_phone)
  end

  def down
    # Add back the old columns if they don't exist
    add_column :units, :tenant_name, :string unless column_exists?(:units, :tenant_name)
    add_column :units, :tenant_phone, :string unless column_exists?(:units, :tenant_phone)

    # Migrate data back from tenants to units
    Tenant.find_each do |tenant|
      unit = tenant.unit
      next unless unit

      unit.update_columns(
        tenant_name: tenant.full_name,
        tenant_phone: tenant.phone
      )
    end
  end
end