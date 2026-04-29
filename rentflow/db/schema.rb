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

ActiveRecord::Schema[8.1].define(version: 2026_04_28_163000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "rent_records", force: :cascade do |t|
    t.decimal "amount_due"
    t.decimal "amount_paid"
    t.decimal "balance"
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
    t.bigint "unit_id", null: false
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
    t.string "role"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "maintenance_logs", "units"
  add_foreign_key "properties", "users"
  add_foreign_key "rent_records", "tenants"
  add_foreign_key "rent_records", "units"
  add_foreign_key "tenants", "units"
  add_foreign_key "units", "properties"
end
