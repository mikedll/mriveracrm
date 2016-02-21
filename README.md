
Please pay a fee to use this software. The fee you pay
can be negotiated and setup at [www.mriveracrm.com](http://www.mriveracrm.com).
You can contact me by email at mrivera@michaelriveraco.com.

Michael Rivera, also known as Mike De La Loza, Owner

# Deploying

Cut a release.

    g frs v1.x

Fix any bugs. Do assets compilation and deploy, if assets have changed. Ensure
amazon keys are defined in the environment, then run the assets deploy command.
    
    RAILS_ENV=production rake assets:deploy  # this does an assets:precompile, too.

Commit manifest.

    g add public/assets/manifest.yml
    g ci -m "Updated manifest."
    
Don't mess up your dev machine.

    rake assets:clean
    g co .   # restore old manifest.

Fix any bugs....are you sure? Then finish release.

    g frf v1.x
    g push
    g co develop # stay on develop branch
    
Both dev and master should go upstream.

    cap production deploy:migrations

That's it. If you're sure you don't have migrations:

    cap production deploy

If you have to, create any incoming Features as long as you have one
MFE:

    RAILS_ENV=production bundle exec rake data_migrations:ensure_features_exist

That command has to be run on production.

## Restart production without deploying

    cap production deploy:upstart_restart

# Development

See `doc/server_setup.md`.

Run specs with Guard:

    > ./script/fine_grained_daemon.rb db/fineGrainedTest.db & # start FineGrained daemon on a test database.
    > bundle exec guard
    
Start everyting:

    > bundle exec foreman start
    
Start web server:

    > bundle exec rails s

See `doc/development.md`.

# Production config

See `doc/server_setup.md`.
