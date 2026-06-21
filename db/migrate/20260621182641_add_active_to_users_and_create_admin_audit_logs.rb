class AddActiveToUsersAndCreateAdminAuditLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :active, :boolean, default: true, null: false
    add_index :users, :active

    create_table :admin_audit_logs do |t|
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :target_type, null: false
      t.bigint :target_id
      t.string :ip_address
      t.text :user_agent
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :admin_audit_logs, :action
    add_index :admin_audit_logs, :target_type
    add_index :admin_audit_logs, [:target_type, :target_id]
    add_index :admin_audit_logs, :created_at
  end
end
