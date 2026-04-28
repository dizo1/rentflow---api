class MigrateTenantDataToTenants < ActiveRecord::Migration[8.1]
  def up
    # Step 1: Create tenants table
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

    # Step 2: Migrate existing tenant data from units to tenants
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

    # Step 3: Remove old tenant columns from units
    remove_column :units, :tenant_name, :string
    remove_column :units, :tenant_phone, :string
  end

  def down
    # Reverse the migration
    add_column :units, :tenant_name, :string
    add_column :units, :tenant_phone, :string

    # Migrate data back from tenants to units
    Tenant.find_each do |tenant|
      unit = tenant.unit
      next unless unit

      unit.update_columns(
        tenant_name: tenant.full_name,
        tenant_phone: tenant.phone
      )
    end

    drop_table :tenants
  end
end
