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

ActiveRecord::Schema[8.1].define(version: 2026_03_28_033715) do
  create_table "discord_invitations", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "discord_user_id", null: false
    t.datetime "expires_at", null: false
    t.bigint "invited_by_id", null: false
    t.string "note"
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["discord_user_id"], name: "index_discord_invitations_on_discord_user_id"
    t.index ["invited_by_id"], name: "index_discord_invitations_on_invited_by_id"
    t.index ["token_digest"], name: "index_discord_invitations_on_token_digest", unique: true
  end

  create_table "minecraft_servers", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "backend_host"
    t.integer "backend_port"
    t.string "container_id"
    t.string "container_name", null: false
    t.string "container_state"
    t.datetime "created_at", null: false
    t.integer "disk_mb", null: false
    t.string "hostname", null: false
    t.string "last_error_message"
    t.datetime "last_started_at"
    t.integer "memory_mb", null: false
    t.string "minecraft_version", null: false
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.string "provider_name"
    t.string "provider_server_id"
    t.string "provider_server_identifier"
    t.string "resolved_minecraft_version"
    t.string "status", default: "provisioning", null: false
    t.string "template_kind", null: false
    t.datetime "updated_at", null: false
    t.string "volume_name", null: false
    t.index ["container_id"], name: "index_minecraft_servers_on_container_id"
    t.index ["container_name"], name: "index_minecraft_servers_on_container_name", unique: true
    t.index ["container_state"], name: "index_minecraft_servers_on_container_state"
    t.index ["hostname"], name: "index_minecraft_servers_on_hostname", unique: true
    t.index ["owner_id"], name: "index_minecraft_servers_on_owner_id"
    t.index ["provider_name", "provider_server_id"], name: "idx_on_provider_name_provider_server_id_01d0332424"
    t.index ["status"], name: "index_minecraft_servers_on_status"
    t.index ["volume_name"], name: "index_minecraft_servers_on_volume_name", unique: true
  end

  create_table "router_routes", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "last_applied_at"
    t.string "last_apply_status", default: "pending", null: false
    t.string "last_healthcheck_status", default: "unknown", null: false
    t.datetime "last_healthchecked_at"
    t.bigint "minecraft_server_id", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_router_routes_on_enabled"
    t.index ["last_apply_status"], name: "index_router_routes_on_last_apply_status"
    t.index ["last_healthcheck_status"], name: "index_router_routes_on_last_healthcheck_status"
    t.index ["minecraft_server_id"], name: "index_router_routes_on_minecraft_server_id", unique: true
  end

  create_table "server_members", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "minecraft_server_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["minecraft_server_id", "user_id"], name: "index_server_members_on_minecraft_server_id_and_user_id", unique: true
    t.index ["minecraft_server_id"], name: "index_server_members_on_minecraft_server_id"
    t.index ["user_id"], name: "index_server_members_on_user_id"
  end

  create_table "sessions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "discord_avatar"
    t.string "discord_global_name"
    t.string "discord_user_id"
    t.string "discord_username"
    t.string "email_address"
    t.datetime "last_discord_login_at"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "user_type", default: "reader", null: false
    t.index ["discord_user_id"], name: "index_users_on_discord_user_id", unique: true
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["user_type"], name: "index_users_on_user_type"
  end

  add_foreign_key "discord_invitations", "users", column: "invited_by_id"
  add_foreign_key "minecraft_servers", "users", column: "owner_id"
  add_foreign_key "router_routes", "minecraft_servers"
  add_foreign_key "server_members", "minecraft_servers"
  add_foreign_key "server_members", "users"
  add_foreign_key "sessions", "users"
end
