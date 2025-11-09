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

ActiveRecord::Schema[8.1].define(version: 2025_11_09_233018) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "dishes", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.decimal "base_price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "dietary_tags", default: []
    t.string "name", null: false
    t.bigint "seller_profile_id", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_dishes_on_active"
    t.index ["seller_profile_id", "name"], name: "index_dishes_on_seller_profile_id_and_name"
    t.index ["seller_profile_id"], name: "index_dishes_on_seller_profile_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp"
    t.string "jti"
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "seller_profiles", force: :cascade do |t|
    t.decimal "average_rating", precision: 3, scale: 2, default: "0.0"
    t.text "bio"
    t.string "business_name", null: false
    t.string "city"
    t.datetime "created_at", null: false
    t.boolean "currently_active", default: false, null: false
    t.integer "followers_count", default: 0, null: false
    t.datetime "last_active_at"
    t.jsonb "operating_hours", default: {}
    t.string "phone"
    t.integer "reviews_count", default: 0, null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "verified", default: false, null: false
    t.string "whatsapp"
    t.index ["city"], name: "index_seller_profiles_on_city"
    t.index ["currently_active"], name: "index_seller_profiles_on_currently_active"
    t.index ["user_id"], name: "index_seller_profiles_on_user_id", unique: true
    t.index ["verified"], name: "index_seller_profiles_on_verified"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.boolean "is_admin", default: false, null: false
    t.datetime "last_seen_at"
    t.string "name", null: false
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "weekly_menu_dishes", force: :cascade do |t|
    t.integer "available_quantity", null: false
    t.datetime "created_at", null: false
    t.bigint "dish_id", null: false
    t.integer "display_order", default: 0
    t.decimal "price_override", precision: 10, scale: 2
    t.integer "remaining_quantity", null: false
    t.datetime "updated_at", null: false
    t.bigint "weekly_menu_id", null: false
    t.index ["dish_id"], name: "index_weekly_menu_dishes_on_dish_id"
    t.index ["display_order"], name: "index_weekly_menu_dishes_on_display_order"
    t.index ["weekly_menu_id", "dish_id"], name: "index_weekly_menu_dishes_on_weekly_menu_id_and_dish_id", unique: true
    t.index ["weekly_menu_id"], name: "index_weekly_menu_dishes_on_weekly_menu_id"
  end

  create_table "weekly_menus", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "available_from", null: false
    t.datetime "available_until", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "seller_profile_id", null: false
    t.string "title"
    t.integer "total_orders_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_weekly_menus_on_active"
    t.index ["available_from"], name: "index_weekly_menus_on_available_from"
    t.index ["available_until"], name: "index_weekly_menus_on_available_until"
    t.index ["seller_profile_id", "available_from"], name: "index_weekly_menus_on_seller_profile_id_and_available_from"
    t.index ["seller_profile_id"], name: "index_weekly_menus_on_seller_profile_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "dishes", "seller_profiles"
  add_foreign_key "seller_profiles", "users"
  add_foreign_key "weekly_menu_dishes", "dishes"
  add_foreign_key "weekly_menu_dishes", "weekly_menus"
  add_foreign_key "weekly_menus", "seller_profiles"
end
