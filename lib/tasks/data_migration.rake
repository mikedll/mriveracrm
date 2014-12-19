
namespace :data_migrations do
  desc "Migration in features"
  task :features_created => :environment do

    raise "Not intended for when system has more than one mfe. " if MarketingFrontEnd.count > 1

    Feature.ensure_master_list_created!

    Feature.all.each do |f|
      mfe = MarketingFrontEnd.first
      mfe.features.push(f) if mfe.features.find_by_id(f.id).nil?
    end

    Business.all.each do |b|
      b.acquire_default_features!
      b.usage_subscription.notify_signup!
    end
  end
end

