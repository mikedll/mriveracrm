
require 'db_control'

namespace :prodrefresh do

  desc "Important record updates from prod to local"
  task :update_importantMar2015 => :environment do
    DbControl.with_output("Updating hosts for development environment") do
      Business.connection.execute "UPDATE businesses SET host = 'dev1.mikedll.com' WHERE host = 'www.michaelriveraco.com'"

      MarketingFrontEnd.connection.execute "UPDATE marketing_front_ends SET host = 'devmarketing.mriveracrm.com' WHERE host = 'www.mriveracrm.com'"
    end
  end

  desc "Clear sensitive data in the db after a prod refresh"
  task :clear_sensitive => :environment do

    raise "Only allow on staging, testing, and dev." if !(Rails.env.development? || Rails.env.staging? || Rails.env.test?)
    raise "Do not run in production." if Rails.env.production?

    DbControl.with_output("Rewriting passwords, emails") do
      [User, Employee, Client, Credential, Invitation].each do |klass|
        i = 0
        klass.find_each do |o|
          o.email = DbControl.email_mutate(o.email, i)

          if klass == User
            o.password = "asdfasdf"
            o.password_confirmation = "asdfasdf"
          end

          o.save!
          i += 1
        end
      end
    end

    DbControl.with_output("Clearing credentials") do
      Credential.find_each do |c|
        c.oauth_token = ""
        c.oauth_secret = ""
        c.oauth2_access_token = ""
        c.oauth2_access_token_expires_at = nil
        c.oauth2_refresh_token = ""
        c.save!
      end
    end

    DbControl.with_output("Clearing Business credentials") do
      Business.find_each do |c|
        c.stripe_secret_key = ""
        c.stripe_publishable_key = ""
        c.google_oauth2_client_id = ""
        c.google_oauth2_client_secret = ""
        c.authorizenet_payment_gateway_id = ""
        c.authorizenet_api_login_id = ""
        c.authorizenet_transaction_key = ""
        # c.google_analytics_id = ""
        c.save!
      end
    end

    DbControl.with_output("Clearing MFE credentials") do
      MarketingFrontEnd.find_each do |c|
        c.google_oauth2_client_id = ""
        c.google_oauth2_client_secret = ""
        c.save!
      end
    end

    DbControl.with_output("Clearing stripe vendor IDs.") do
      StripePaymentGatewayProfile.find_each do |s|
        s.vendor_id = ""
        s.save!
      end
    end
  end

  desc "Important record updates from prod to local"
  task :update_importantMar2015_2 => [:environment, 'data_migrations:features_created'] do
    DbControl.with_output("Updating Google auth secretes for local dev") do
      MarketingFrontEnd.connection.execute "UPDATE marketing_front_ends SET google_oauth2_client_id = '647124770183-int2l7mp0j4m547r627su062l7pjh0lp.apps.googleusercontent.com', google_oauth2_client_secret = 'yI7wZuFrd7pBS67-KnpbUlfQ' WHERE host = 'devmarketing.mriveracrm.com'"

      Business.connection.execute "UPDATE businesses SET google_oauth2_client_id = '647124770183.apps.googleusercontent.com', google_oauth2_client_secret = 'q00FkSldcDe15IMHQrzvcuJj' WHERE host = 'dev1.mikedll.com'"
    end

    safe_email = AppConfiguration.get('safe_admin_email')
    b = Business.find_by_host 'dev1.mikedll.com'
    b.an_owner.email = safe_email
    b.an_owner.save!
    c = b.an_owner.credentials.first
    c.email = b.an_owner.email
    c.save!
  end

end
