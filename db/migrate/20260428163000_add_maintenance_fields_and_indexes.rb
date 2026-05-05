class AddMaintenanceFieldsAndIndexes < ActiveRecord::Migration[8.1]
  def change
    # Add priority enum column as string
    add_column :maintenance_logs, :priority, :string, default: 'medium', null: false

    # Add reported_date (date field for when issue was reported)
    add_column :maintenance_logs, :reported_date, :date, null: false, default: -> { 'CURRENT_DATE' }

    # Add assigned_to (could be vendor name, technician name, etc.)
    add_column :maintenance_logs, :assigned_to, :string

    # Add notes (text for additional comments/updates)
    add_column :maintenance_logs, :notes, :text

    # Add index for filtering by status and priority
    add_index :maintenance_logs, [:status, :priority]
    add_index :maintenance_logs, :priority

    # Add index for reported_date queries (e.g., find logs reported in date range)
    add_index :maintenance_logs, :reported_date

    # Add index for assigned_to for filtering by assignee
    add_index :maintenance_logs, :assigned_to

    # Add index for resolved_at to quickly find recently resolved logs
    add_index :maintenance_logs, :resolved_at
  end
end
