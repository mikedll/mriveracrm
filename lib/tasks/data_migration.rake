
namespace :data_migrations do
  desc "Migration in features"
  task :features_created => :environment do
    Feature.ensure_master_list_created!
  end
end

