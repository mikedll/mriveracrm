

namespace :prodrefresh do
  desc "Clear sensitive data in the db after a prod refresh"
  task :clearsensitive => :environment do
    Client.find_each do |c|
      c.email = "none#{c.id}@mikedll.com"
      c.save!
    end

    Credential.find_each do |c|
      c.oauth_token = ""
      c.oauth_secret = ""
      c.oauth2_access_token = ""
      c.oauth2_access_token_expires_at = nil
      c.oauth2_refresh_token = ""
      c.save!
    end

    StripePaymentGatewayProfile.find_each do |s|
      s.vendor_id = "cus_23BHCAXiQa9sKD"
      s.save!
    end
  end
end
