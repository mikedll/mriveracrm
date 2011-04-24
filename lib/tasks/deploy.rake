
if Rake.application.tasks.map(&:name).include? 'before_deploy'
  Rake::Task[:before_deploy].enhance ['heroku:maintenance']
  Rake::Task[:after_deploy].enhance ['heroku:maintenance_off']
end

