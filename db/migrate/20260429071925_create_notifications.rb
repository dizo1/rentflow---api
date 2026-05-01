class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :message
      t.string :notification_type
      t.boolean :read_status, default: false, null: false

      t.timestamps
    end

    # Add indexes for common queries (reference already creates index on user_id)
    add_index :notifications, :notification_type
    add_index :notifications, :read_status
    add_index :notifications, [:user_id, :read_status] # For finding unread notifications for a user
  end
end