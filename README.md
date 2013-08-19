



# Deploying to production

Cut a release.

    g f release start v1.x

Fix any bugs. Do assets compilation and deploy.
    
    RAILS_ENV=production rake assets:deploy  # this does an assets:precompile, too.

Commit manifest.

    # whatever you git commit manuver is

Don't mess up your dev machine.

    rake assets:clean

Fix any bugs....are you sure? Then finish release.

    g f release finish v1.x
    g push
    
Both dev and master should go upstream.

    cap production deploy:migrations

That's it. If you're sure you don't have migrations:

    cap production deploy


