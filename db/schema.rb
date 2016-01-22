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

ActiveRecord::Schema.define(:version => 20160118041554) do

  create_table "businesses", :force => true do |t|
    t.string   "name",                            :default => "",    :null => false
    t.string   "host",                            :default => "",    :null => false
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.string   "stripe_secret_key",               :default => "",    :null => false
    t.string   "stripe_publishable_key",          :default => "",    :null => false
    t.string   "google_oauth2_client_id",         :default => "",    :null => false
    t.string   "google_oauth2_client_secret",     :default => "",    :null => false
    t.string   "authorizenet_payment_gateway_id", :default => "",    :null => false
    t.string   "authorizenet_api_login_id",       :default => "",    :null => false
    t.string   "authorizenet_transaction_key",    :default => "",    :null => false
    t.boolean  "authorizenet_test",               :default => false, :null => false
    t.string   "handle",                          :default => "",    :null => false
    t.text     "splash_html",                     :default => "",    :null => false
    t.text     "contact_text",                    :default => "",    :null => false
    t.integer  "default_mfe_id",                  :default => 0,     :null => false
    t.string   "google_public_api_key",           :default => "",    :null => false
    t.string   "it_monitored_computers_key",      :default => ""
  end

  create_table "clients", :force => true do |t|
    t.integer  "business_id"
    t.string   "first_name",      :default => "",    :null => false
    t.string   "last_name",       :default => "",    :null => false
    t.string   "email",           :default => "",    :null => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
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
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
  end

  add_index "credentials", ["business_id", "email"], :name => "index_credentials_on_business_id_and_email", :unique => true

  create_table "detected_errors", :force => true do |t|
    t.text     "message"
    t.integer  "client_id"
    t.integer  "business_id"
    t.integer  "user_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "employees", :force => true do |t|
    t.integer  "business_id"
    t.string   "first_name",  :default => "", :null => false
    t.string   "last_name",   :default => "", :null => false
    t.string   "email",       :default => "", :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.string   "role",        :default => "", :null => false
  end

  create_table "feature_pricings", :force => true do |t|
    t.integer  "feature_id",                                :default => 0,   :null => false
    t.decimal  "price",      :precision => 10, :scale => 2, :default => 0.0, :null => false
    t.integer  "generation",                                :default => 0,   :null => false
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
  end

  create_table "feature_provisions", :force => true do |t|
    t.integer  "feature_id",             :default => 0, :null => false
    t.integer  "marketing_front_end_id", :default => 0, :null => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  create_table "feature_selections", :force => true do |t|
    t.integer  "feature_id",            :default => 0, :null => false
    t.integer  "usage_subscription_id", :default => 0, :null => false
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
  end

  create_table "features", :force => true do |t|
    t.integer  "bit_index",   :default => 0,  :null => false
    t.string   "name",        :default => "", :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.string   "public_name", :default => "", :null => false
  end

  create_table "images", :force => true do |t|
    t.string   "data"
    t.integer  "project_id"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
    t.integer  "business_id"
    t.string   "data_original_filename"
    t.string   "data_unique_id"
  end

  create_table "invitations", :force => true do |t|
    t.integer  "business_id"
    t.integer  "employee_id"
    t.integer  "client_id"
    t.string   "email",       :default => "", :null => false
    t.string   "status"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.string   "handle",      :default => ""
  end

  create_table "invoices", :force => true do |t|
    t.decimal  "total"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.text     "description"
    t.string   "status"
    t.datetime "date"
    t.integer  "client_id"
    t.string   "title"
    t.string   "pdf_file"
    t.string   "pdf_file_unique_id"
    t.string   "pdf_file_original_filename"
  end

  create_table "it_monitored_computers", :force => true do |t|
    t.integer  "business_id",                                   :null => false
    t.string   "name",                       :default => "",    :null => false
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.string   "last_error",                 :default => "",    :null => false
    t.boolean  "active",                     :default => false, :null => false
    t.datetime "last_heartbeat_received_at"
    t.string   "hostname",                   :default => "",    :null => false
    t.string   "last_result",                :default => "",    :null => false
    t.boolean  "down",                       :default => false, :null => false
  end

  create_table "letters", :force => true do |t|
    t.integer "business_id", :null => false
    t.string  "title"
    t.text    "body"
  end

  create_table "lifecycle_notifications", :force => true do |t|
    t.integer  "business_id", :default => 0,  :null => false
    t.string   "identifier",  :default => "", :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.text     "body",        :default => "", :null => false
  end

  create_table "link_orderings", :force => true do |t|
    t.integer  "business_id",                     :null => false
    t.string   "title",           :default => "", :null => false
    t.string   "referenced_link", :default => "", :null => false
    t.integer  "priority",                        :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "marketing_front_ends", :force => true do |t|
    t.string   "title",                       :default => "", :null => false
    t.string   "host",                        :default => "", :null => false
    t.string   "google_oauth2_client_id",     :default => "", :null => false
    t.string   "google_oauth2_client_secret", :default => "", :null => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  create_table "notes", :force => true do |t|
    t.integer  "client_id"
    t.datetime "recorded_at"
    t.text     "body"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "notifications", :force => true do |t|
    t.integer  "business_id", :default => 0,  :null => false
    t.string   "identifier",  :default => "", :null => false
    t.string   "to",          :default => "", :null => false
    t.string   "from",        :default => "", :null => false
    t.string   "subject",     :default => "", :null => false
    t.text     "body",        :default => "", :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  create_table "pages", :force => true do |t|
    t.integer  "business_id",                      :null => false
    t.string   "title",         :default => "",    :null => false
    t.string   "slug",          :default => "",    :null => false
    t.boolean  "active",        :default => false, :null => false
    t.text     "body",          :default => "",    :null => false
    t.text     "compiled_body", :default => "",    :null => false
    t.integer  "link_priority",                    :null => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  create_table "payment_gateway_profiles", :force => true do |t|
    t.string   "type"
    t.integer  "payment_gateway_profilable_id"
    t.string   "vendor_id"
    t.string   "card_profile_id"
    t.string   "card_last_4"
    t.string   "card_brand"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.string   "payment_gateway_profilable_type", :default => "", :null => false
    t.datetime "stripe_trial_ends_at"
    t.datetime "stripe_current_period_ends_at"
    t.string   "stripe_plan",                     :default => ""
    t.string   "stripe_status",                   :default => ""
  end

  create_table "product_images", :force => true do |t|
    t.integer  "image_id"
    t.integer  "product_id"
    t.boolean  "active",     :default => false, :null => false
    t.boolean  "primary",    :default => false, :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "products", :force => true do |t|
    t.integer  "business_id"
    t.string   "name",         :default => "",    :null => false
    t.text     "description",  :default => "",    :null => false
    t.decimal  "price"
    t.float    "weight"
    t.string   "weight_units", :default => "",    :null => false
    t.boolean  "active",       :default => false, :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "projects", :force => true do |t|
    t.string   "title"
    t.string   "link"
    t.text     "description"
    t.string   "tech"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "business_id"
  end

  create_table "settings", :force => true do |t|
    t.string   "key",        :default => "",       :null => false
    t.string   "value",      :default => "",       :null => false
    t.string   "value_type", :default => "String", :null => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
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
    t.datetime "created_at",                                                                                :null => false
    t.datetime "updated_at",                                                                                :null => false
    t.string   "type",                                                                                      :null => false
    t.string   "outside_id"
    t.string   "outside_vendor"
  end

  create_table "usage_subscriptions", :force => true do |t|
    t.integer  "business_id", :default => 0, :null => false
    t.integer  "generation",  :default => 0, :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  create_table "users", :force => true do |t|
    t.integer  "business_id"
    t.string   "first_name",             :default => "",    :null => false
    t.string   "last_name",              :default => "",    :null => false
    t.string   "email",                  :default => "",    :null => false
    t.integer  "sign_in_count"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "timezone"
    t.integer  "employee_id"
    t.integer  "client_id"
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.boolean  "is_admin",               :default => false
  end

  add_index "users", ["business_id", "confirmation_token"], :name => "index_users_on_business_id_and_confirmation_token", :unique => true
  add_index "users", ["business_id", "email"], :name => "index_users_on_business_id_and_email", :unique => true
  add_index "users", ["business_id", "reset_password_token"], :name => "index_users_on_business_id_and_reset_password_token", :unique => true

end
