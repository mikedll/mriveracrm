# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130318003712) do

  create_table "active_admin_comments", :force => true do |t|
    t.integer  "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "admin_users", :force => true do |t|
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true

  create_table "businesses", :force => true do |t|
    t.string   "name",       :default => "", :null => false
    t.string   "domain",     :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "businesses_users", :id => false, :force => true do |t|
    t.integer "business_id"
    t.integer "user_id"
  end

  create_table "clients", :force => true do |t|
    t.integer  "business_id"
    t.string   "first_name",  :default => "", :null => false
    t.string   "last_name",   :default => "", :null => false
    t.string   "email",       :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "clients_users", :id => false, :force => true do |t|
    t.integer "client_id"
    t.integer "user_id"
  end

  create_table "credentials", :force => true do |t|
    t.integer  "user_id"
    t.string   "email",         :default => "", :null => false
    t.string   "credential_id"
    t.string   "oauth_token"
    t.string   "oauth_secret"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "credentials", ["email"], :name => "index_credentials_on_email", :unique => true

  create_table "detected_errors", :force => true do |t|
    t.text     "message"
    t.integer  "client_id"
    t.integer  "business_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", :force => true do |t|
    t.string   "data"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invitations", :force => true do |t|
    t.integer  "business_id"
    t.integer  "client_id"
    t.string   "email",       :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invoices", :force => true do |t|
    t.integer  "business_id"
    t.decimal  "total"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.string   "status",      :null => false
    t.datetime "date"
    t.integer  "client_id"
  end

  create_table "payment_gateway_profiles", :force => true do |t|
    t.string   "type"
    t.integer  "client_id"
    t.string   "vendor_id"
    t.string   "card_profile_id"
    t.string   "card_last_4"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.string   "title"
    t.string   "link"
    t.text     "description"
    t.string   "tech"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "business_id"
  end

  create_table "transactions", :force => true do |t|
    t.integer  "invoice_id"
    t.integer  "payment_gateway_profile_id"
    t.string   "status"
    t.decimal  "amount",                                    :precision => 10, :scale => 2, :default => 0.0
    t.string   "vendor_id"
    t.text     "error"
    t.integer  "authorizenet_gateway_response_code"
    t.integer  "authorizenet_gateway_response_reason_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "first_name",         :default => "", :null => false
    t.string   "last_name",          :default => "", :null => false
    t.string   "email",              :default => "", :null => false
    t.integer  "sign_in_count"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "timezone"
  end

end
