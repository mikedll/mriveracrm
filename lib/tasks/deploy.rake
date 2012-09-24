
if Rake.application.tasks.map(&:name).include? 'before_deploy'

  Rake::Task[:before_deploy].enhance do
     Rake::Task['assets:deploy'].invoke
     Rake::Task['heroku:maintenance'].execute
  end

  Rake::Task[:after_deploy].enhance do
    Rake::Task['heroku:maintenance_off'].execute
  end
end
