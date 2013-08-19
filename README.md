



# Deploying to production

    # move to release branch
    
    rake assets:precompile   # generate manifest
    
    # git commit manifest file
    # git merge to master
    # git push
    
    RAILS_ENV=production rake assets:deploy


    # without migrations
    cap production deploy

    # if you have migrations
    cap production deploy:migrations
