class CreateReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :reminders do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.references :rent_record, null: true, foreign_key: true
      t.references :maintenance_log, null: true, foreign_key: true
      t.string :reminder_type
      t.text :message
      t.string :channel
      t.string :status
      t.datetime :scheduled_for
      t.datetime :sent_at
      t.datetime :failed_at
      t.text :failure_reason

      t.timestamps
    end

    # Add indexes for common queries (references already create indexes for foreign keys)
    add_index :reminders, :reminder_type
    add_index :reminders, :channel
    add_index :reminders, :status
    add_index :reminders, :scheduled_for
    add_index :reminders, [:unit_id, :status] # For finding unit reminders by status
    add_index :reminders, [:tenant_id, :status] # For finding tenant reminders by status
  end
end