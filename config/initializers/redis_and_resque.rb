
# This is picked up by redis-objects.
Redis.current = Redis.new(:url => AppConfiguration.get('redis'))

# Use same redis for resque.
Resque.redis = Redis.current

Resque.logger.level = 1 # :debug, :info, :warn, :error, :fatal

# Get own connection to PostgreSQL
# https://devcenter.heroku.com/articles/forked-pg-connections#resque-ruby-queuing
Resque.before_fork { ActiveRecord::Base.connection.disconnect! }
Resque.after_fork { ActiveRecord::Base.establish_connection }
