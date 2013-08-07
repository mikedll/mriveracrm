# encoding: UTF-8
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

ActiveRecord::Schema.define(:version => 20130805070257) do

  create_table "businesses", :force => true do |t|
    t.string   "name",       :default => "", :null => false
    t.string   "domain",     :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "clients", :force => true do |t|
    t.integer  "business_id"
    t.string   "first_name",      :default => "",    :null => false
    t.string   "last_name",       :default => "",    :null => false
    t.string   "email",           :default => "",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "website_url",     :default => "",    :null => false
    t.string   "skype_id",        :default => "",    :null => false
    t.datetime "last_contact_at"
    t.datetime "next_contact_at"
    t.string   "phone",           :default => "",    :null => false
    t.string   "phone_2",         :default => "",    :null => false
    t.boolean  "archived",        :default => false, :null => false
    t.string   "company",         :default => "",    :null => false
    t.string   "address_line_1",  :default => "",    :null => false
    t.string   "address_line_2",  :default => "",    :null => false
    t.string   "city",            :default => "",    :null => false
    t.string   "state",           :default => "",    :null => false
    t.string   "zip",             :default => "",    :null => false
  end

  create_table "credentials", :force => true do |t|
    t.integer  "business_id"
    t.integer  "user_id"
    t.string   "name",                           :default => "", :null => false
    t.string   "uid",                            :default => "", :null => false
    t.string   "email",                          :default => "", :null => false
    t.string   "provider",                       :default => "", :null => false
    t.string   "oauth_token"
    t.string   "oauth_secret"
    t.string   "oauth2_access_token"
    t.datetime "oauth2_access_token_expires_at"
    t.string   "oauth2_refresh_token"
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

  create_table "employees", :force => true do |t|
    t.integer  "business_id"
    t.string   "first_name",  :default => "", :null => false
    t.string   "last_name",   :default => "", :null => false
    t.string   "email",       :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", :force => true do |t|
    t.string   "data"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "business_id"
  end

  create_table "invitations", :force => true do |t|
    t.integer  "business_id"
    t.integer  "employee_id"
    t.integer  "client_id"
    t.string   "email",       :default => "", :null => false
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invoices", :force => true do |t|
    t.decimal  "total"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.string   "status"
    t.datetime "date"
    t.integer  "client_id"
    t.string   "title"
  end

  create_table "notes", :force => true do |t|
    t.integer  "client_id"
    t.datetime "recorded_at"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payment_gateway_profiles", :force => true do |t|
    t.string   "type"
    t.integer  "client_id"
    t.string   "vendor_id"
    t.string   "card_profile_id"
    t.string   "card_last_4"
    t.string   "card_brand"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "product_images", :force => true do |t|
    t.integer  "image_id"
    t.integer  "product_id"
    t.boolean  "active",     :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "products", :force => true do |t|
    t.integer  "business_id"
    t.string   "name",         :default => "", :null => false
    t.text     "description",  :default => "", :null => false
    t.decimal  "price"
    t.float    "weight"
    t.string   "weight_units", :default => "", :null => false
    t.boolean  "active"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
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
    t.string   "type",                                                                                      :null => false
    t.string   "outside_id"
    t.string   "outside_vendor"
  end

  create_table "users", :force => true do |t|
    t.integer  "business_id"
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
    t.integer  "employee_id"
    t.integer  "client_id"
  end

end
