class AddPropertyStatusToProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :properties, :property_status, :string, default: 'pending', null: false
  end
end
