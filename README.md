



# Deploying to production

    # move to release branch
    
    RAILS_ENV=production rake assets:deploy  # this does an assets:precompile, too.

    # git commit manifest file that was just generated.
    # git merge to master
    # git push


    # without migrations
    cap production deploy

    # if you have migrations
    cap production deploy:migrations

    rake assets:clean  # don't mess up your dev machine.
