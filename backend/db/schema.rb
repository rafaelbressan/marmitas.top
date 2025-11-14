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

ActiveRecord::Schema[8.1].define(version: 2025_11_14_144337) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"

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

  create_table "device_tokens", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "device_name"
    t.datetime "last_used_at"
    t.string "platform", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["token"], name: "index_device_tokens_on_token"
    t.index ["user_id", "token", "platform"], name: "index_device_tokens_uniqueness", unique: true
    t.index ["user_id"], name: "index_device_tokens_on_user_id"
  end

  create_table "dishes", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.decimal "base_price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "dietary_tags", default: []
    t.integer "favorites_count", default: 0, null: false
    t.string "name", null: false
    t.bigint "seller_profile_id", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_dishes_on_active"
    t.index ["seller_profile_id", "name"], name: "index_dishes_on_seller_profile_id_and_name"
    t.index ["seller_profile_id"], name: "index_dishes_on_seller_profile_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "favoritable_id", null: false
    t.string "favoritable_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["favoritable_type", "favoritable_id"], name: "index_favorites_on_favoritable"
    t.index ["user_id", "favoritable_type", "favoritable_id"], name: "index_favorites_uniqueness", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp"
    t.string "jti"
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "review_helpfuls", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "review_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["review_id", "user_id"], name: "index_review_helpfuls_on_review_id_and_user_id", unique: true
    t.index ["review_id"], name: "index_review_helpfuls_on_review_id"
    t.index ["user_id"], name: "index_review_helpfuls_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.string "dish_name"
    t.integer "edit_count", default: 0
    t.date "encounter_date", null: false
    t.decimal "encounter_latitude", precision: 10, scale: 6
    t.decimal "encounter_longitude", precision: 10, scale: 6
    t.datetime "encounter_timestamp"
    t.string "flag_reason"
    t.boolean "flagged", default: false
    t.integer "helpful_count", default: 0
    t.datetime "last_edited_at"
    t.datetime "moderated_at"
    t.bigint "moderated_by_id"
    t.text "moderation_note"
    t.string "moderation_status", default: "published"
    t.integer "rating", null: false
    t.bigint "seller_profile_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "verified_encounter", default: false
    t.bigint "weekly_menu_id"
    t.index ["created_at"], name: "index_reviews_on_created_at"
    t.index ["encounter_date"], name: "index_reviews_on_encounter_date"
    t.index ["flagged"], name: "index_reviews_on_flagged"
    t.index ["moderated_by_id"], name: "index_reviews_on_moderated_by_id"
    t.index ["moderation_status"], name: "index_reviews_on_moderation_status"
    t.index ["rating"], name: "index_reviews_on_rating"
    t.index ["seller_profile_id"], name: "index_reviews_on_seller_profile_id"
    t.index ["user_id", "seller_profile_id", "encounter_date"], name: "index_reviews_on_user_seller_date", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
    t.index ["weekly_menu_id"], name: "index_reviews_on_weekly_menu_id"
    t.check_constraint "rating >= 1 AND rating <= 5", name: "reviews_rating_range"
  end

  create_table "seller_profiles", force: :cascade do |t|
    t.datetime "arrived_at"
    t.decimal "average_rating", precision: 3, scale: 2, default: "0.0"
    t.text "bio"
    t.string "business_name", null: false
    t.string "city"
    t.datetime "created_at", null: false
    t.bigint "current_location_id"
    t.boolean "currently_active", default: false, null: false
    t.integer "favorites_count", default: 0, null: false
    t.integer "followers_count", default: 0, null: false
    t.datetime "last_active_at"
    t.datetime "leaving_at"
    t.jsonb "operating_hours", default: {}
    t.string "phone"
    t.integer "rating_1_count", default: 0
    t.integer "rating_2_count", default: 0
    t.integer "rating_3_count", default: 0
    t.integer "rating_4_count", default: 0
    t.integer "rating_5_count", default: 0
    t.integer "reviews_count", default: 0, null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "verified", default: false, null: false
    t.string "whatsapp"
    t.index ["arrived_at"], name: "index_seller_profiles_on_arrived_at"
    t.index ["average_rating"], name: "index_seller_profiles_on_average_rating"
    t.index ["city"], name: "index_seller_profiles_on_city"
    t.index ["current_location_id"], name: "index_seller_profiles_on_current_location_id"
    t.index ["currently_active"], name: "index_seller_profiles_on_currently_active"
    t.index ["leaving_at"], name: "index_seller_profiles_on_leaving_at"
    t.index ["user_id"], name: "index_seller_profiles_on_user_id", unique: true
    t.index ["verified"], name: "index_seller_profiles_on_verified"
  end

# Could not dump table "selling_locations" because of following StandardError
#   Unknown type 'geography' for column 'lonlat'


  create_table "spatial_ref_sys", primary_key: "srid", id: :integer, default: nil, force: :cascade do |t|
    t.string "auth_name", limit: 256
    t.integer "auth_srid"
    t.string "proj4text", limit: 2048
    t.string "srtext", limit: 2048
    t.check_constraint "srid > 0 AND srid <= 998999", name: "spatial_ref_sys_srid_check"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.boolean "is_admin", default: false, null: false
    t.datetime "last_seen_at"
    t.string "name", null: false
    t.jsonb "notification_preferences", default: {"new_menus"=>true, "promotions"=>false, "order_updates"=>true, "seller_arrivals"=>true}, null: false
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
    t.datetime "deleted_at"
    t.text "description"
    t.bigint "seller_profile_id", null: false
    t.string "title"
    t.integer "total_orders_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_weekly_menus_on_active"
    t.index ["available_from"], name: "index_weekly_menus_on_available_from"
    t.index ["available_until"], name: "index_weekly_menus_on_available_until"
    t.index ["deleted_at"], name: "index_weekly_menus_on_deleted_at"
    t.index ["seller_profile_id", "available_from"], name: "index_weekly_menus_on_seller_profile_id_and_available_from"
    t.index ["seller_profile_id"], name: "index_weekly_menus_on_seller_profile_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "device_tokens", "users"
  add_foreign_key "dishes", "seller_profiles"
  add_foreign_key "favorites", "users"
  add_foreign_key "review_helpfuls", "reviews"
  add_foreign_key "review_helpfuls", "users"
  add_foreign_key "reviews", "seller_profiles"
  add_foreign_key "reviews", "users"
  add_foreign_key "reviews", "users", column: "moderated_by_id"
  add_foreign_key "reviews", "weekly_menus"
  add_foreign_key "seller_profiles", "selling_locations", column: "current_location_id"
  add_foreign_key "seller_profiles", "users"
  add_foreign_key "selling_locations", "seller_profiles"
  add_foreign_key "weekly_menu_dishes", "dishes"
  add_foreign_key "weekly_menu_dishes", "weekly_menus"
  add_foreign_key "weekly_menus", "seller_profiles"
end
