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

ActiveRecord::Schema[8.1].define(version: 2026_04_27_134748) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "maintenance_logs", force: :cascade do |t|
    t.decimal "cost"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "resolved_at"
    t.string "status"
    t.string "title"
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_id"], name: "index_maintenance_logs_on_unit_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "name"
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
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["unit_id"], name: "index_rent_records_on_unit_id"
  end

  create_table "units", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "deposit_amount"
    t.string "occupancy_status"
    t.bigint "property_id", null: false
    t.decimal "rent_amount"
    t.string "tenant_name"
    t.string "tenant_phone"
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
  add_foreign_key "rent_records", "units"
  add_foreign_key "units", "properties"
end
