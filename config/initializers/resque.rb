# Load the redis configuration from resque.yml
Resque.redis = YAML.load_file(File.join(Rails.root, "config", "resque.yml"))[Rails.env.to_s]

# Get own connection to PostgreSQL
# https://devcenter.heroku.com/articles/forked-pg-connections#resque-ruby-queuing
Resque.before_fork { ActiveRecord::Base.connection.disconnect! }
Resque.after_fork { ActiveRecord::Base.establish_connection }
