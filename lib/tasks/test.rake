
namespace :test do
  desc "Kill authorize.net profiles in test mode"
  task :wipe_authorizenet_profiles => :environment do
    raise "Only run in test mode" if !Rails.env.test?
    
  end


  desc "Delete all stripe customers in test mode."
  task :delete_stripe_customers => :environment do
    raise "Only run in test mode" if !Rails.env.test?
    raise "Never run this in prod" if Rails.env.production?

    deleted_this_round = 1
    while deleted_this_round > 0
      deleted_this_round = 0
      Stripe::Customer.all(:count => 100).data.each do |c| 
        puts "Deleting #{c.id}"
        c.delete
        deleted_this_round += 1
      end
    end
  end
end

