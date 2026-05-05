# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_02_084137) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "blocklisted_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp"
    t.string "token"
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_blocklisted_tokens_on_token"
  end

  create_table "maintenance_logs", force: :cascade do |t|
    t.string "assigned_to"
    t.decimal "cost"
    t.datetime "created_at", null: false
    t.text "description"
    t.text "notes"
    t.string "priority", default: "medium", null: false
    t.date "reported_date", default: -> { "CURRENT_DATE" }, null: false
    t.datetime "resolved_at"
    t.string "status"
    t.string "title"
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to"], name: "index_maintenance_logs_on_assigned_to"
    t.index ["priority"], name: "index_maintenance_logs_on_priority"
    t.index ["reported_date"], name: "index_maintenance_logs_on_reported_date"
    t.index ["resolved_at"], name: "index_maintenance_logs_on_resolved_at"
    t.index ["status", "priority"], name: "index_maintenance_logs_on_status_and_priority"
    t.index ["unit_id"], name: "index_maintenance_logs_on_unit_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "message"
    t.string "notification_type"
    t.boolean "read_status", default: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["read_status"], name: "index_notifications_on_read_status"
    t.index ["user_id", "read_status"], name: "index_notifications_on_user_id_and_read_status"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "paid_at"
    t.string "payment_method"
    t.integer "plan", null: false
    t.string "reference", null: false
    t.integer "status", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["reference"], name: "index_payments_on_reference", unique: true
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "property_status", default: "pending", null: false
    t.string "property_type"
    t.string "status"
    t.integer "total_units"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "reminders", force: :cascade do |t|
    t.string "channel"
    t.datetime "created_at", null: false
    t.datetime "failed_at"
    t.text "failure_reason"
    t.bigint "maintenance_log_id"
    t.text "message"
    t.string "reminder_type"
    t.bigint "rent_record_id"
    t.datetime "scheduled_for"
    t.datetime "sent_at"
    t.string "status"
    t.bigint "tenant_id", null: false
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["channel"], name: "index_reminders_on_channel"
    t.index ["maintenance_log_id"], name: "index_reminders_on_maintenance_log_id"
    t.index ["reminder_type"], name: "index_reminders_on_reminder_type"
    t.index ["rent_record_id"], name: "index_reminders_on_rent_record_id"
    t.index ["scheduled_for"], name: "index_reminders_on_scheduled_for"
    t.index ["status"], name: "index_reminders_on_status"
    t.index ["tenant_id", "status"], name: "index_reminders_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_reminders_on_tenant_id"
    t.index ["unit_id", "status"], name: "index_reminders_on_unit_id_and_status"
    t.index ["unit_id"], name: "index_reminders_on_unit_id"
  end

  create_table "rent_records", force: :cascade do |t|
    t.decimal "amount_due"
    t.decimal "amount_paid", default: "0.0"
    t.decimal "balance", default: "0.0"
    t.datetime "created_at", null: false
    t.date "due_date"
    t.integer "month"
    t.datetime "paid_at"
    t.string "status"
    t.bigint "tenant_id"
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["status", "due_date"], name: "index_rent_records_on_status_and_due_date"
    t.index ["tenant_id"], name: "index_rent_records_on_tenant_id"
    t.index ["unit_id", "month", "year"], name: "index_rent_records_on_unit_month_year", unique: true
    t.index ["unit_id"], name: "index_rent_records_on_unit_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.integer "plan", null: false
    t.integer "sms_used", default: 0
    t.datetime "starts_at"
    t.integer "status", null: false
    t.datetime "trial_ends_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "emergency_contact"
    t.string "full_name", null: false
    t.date "lease_end", null: false
    t.date "lease_start", null: false
    t.date "move_in_date", null: false
    t.string "national_id"
    t.string "phone", null: false
    t.string "status", default: "pending_move_in", null: false
    t.bigint "unit_id"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_tenants_on_email", unique: true
    t.index ["lease_end"], name: "index_tenants_on_lease_end"
    t.index ["status"], name: "index_tenants_on_status"
    t.index ["unit_id"], name: "index_tenants_on_unit_id", unique: true
  end

  create_table "units", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "deposit_amount"
    t.string "occupancy_status"
    t.bigint "property_id", null: false
    t.decimal "rent_amount"
    t.string "unit_number"
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_units_on_property_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.datetime "password_reset_sent_at"
    t.string "password_reset_token"
    t.string "role"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "maintenance_logs", "units"
  add_foreign_key "notifications", "users"
  add_foreign_key "payments", "users"
  add_foreign_key "properties", "users"
  add_foreign_key "reminders", "maintenance_logs"
  add_foreign_key "reminders", "rent_records"
  add_foreign_key "reminders", "tenants"
  add_foreign_key "reminders", "units"
  add_foreign_key "rent_records", "tenants"
  add_foreign_key "rent_records", "units"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "tenants", "units"
  add_foreign_key "units", "properties"
end
