
namespace :test do
  desc "Kill authorize.net profiles in test mode"
  task :wipe_authorizenet_profiles => :environment do
    raise "Only run in test mode" if !Rails.env.test?
    
  end
end
