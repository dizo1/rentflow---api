class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :plan, null: false
      t.integer :status, null: false
      t.datetime :trial_ends_at
      t.datetime :starts_at
      t.datetime :ends_at
      t.integer :sms_used, default: 0

      t.timestamps
    end
  end
end
