class MakeUnitIdOptionalOnTenants < ActiveRecord::Migration[8.1]
  def change
    change_column_null :tenants, :unit_id, true
  end
end