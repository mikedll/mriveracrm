
namespace :prodrefresh do
  task :clearsensistive do
    Client.all.each do |c|
      c.email = "none@mikedll.com"
      c.save!
    end

    StripePaymentGatewayProfile.each do |s|
      s.vendor_id = "xxx"
      s.save!
    end
  end
end
