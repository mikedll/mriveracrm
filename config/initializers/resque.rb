# Load the redis configuration from resque.yml
Resque.redis = AppConfiguration.get('redis')

Resque.logger.level = 1 # :debug, :info, :warn, :error, :fatal

# Get own connection to PostgreSQL
# https://devcenter.heroku.com/articles/forked-pg-connections#resque-ruby-queuing
Resque.before_fork { ActiveRecord::Base.connection.disconnect! }
Resque.after_fork { ActiveRecord::Base.establish_connection }
