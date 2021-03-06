
namespace :data_migrations do

  desc "Ensure all features exist"
  task :ensure_features_exist => :environment do
    raise "Not intended for when system has more than one mfe. " if MarketingFrontEnd.count > 1

    Feature.ensure_master_list_created!
    Feature.ensure_minimal_pricings!

    Feature.all.each do |f|
      mfe = MarketingFrontEnd.first
      mfe.features.push(f) if mfe.features.find_by_id(f.id).nil?
    end
  end

  # Probably shouldn't use this anymore until you modify
  # it to respect expired trials.
  desc "Migration in features"
  task :features_created => [:environment, :ensure_features_exist] do

    Business.unscoped.all.each do |b|
      b.usage_subscription.require_payment_gateway_profile

      b.acquire_default_features! if b.usage_subscription.features.count == 0

      if b.an_owner.nil?
        e = b.employees.first
        e.role = Employee::Roles::OWNER
        e.save!
      end

      b.usage_subscription.ensure_correct_plan!
    end
  end

  desc "Notify signups."
  task :notify_signups => :environment do
    Business.unscoped.all.each do |b|
      b.usage_subscription.reload
      b.usage_subscription.notify_signup!
    end
  end
end

