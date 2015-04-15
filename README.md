
Please pay a fee to use this software. The fee you pay
can be negotiated and setup at [www.mriveracrm.com](http://www.mriveracrm.com).
You can contact me by email at mrivera@michaelriveraco.com.

Michael Rivera, also known as Mike De La Loza, Owner

# Development setup

See `doc/server_setup.md`.

Start server:

    > rails s

Start resque worker

    > bundle exec resque work

# Typical Views

  We have a gui-container class which is typically tied to a Stacked view,
  which knows how to animate different stacked views. These must
  resize width, height, and margins when the page resizes.
  
  Inside of that are many app-view classes. These must resize width,
  height, but unlike the above, not margin-left or margin-top, when
  the page resizes. These also hold shadow decorations.
  
  Almost every single page in the app, even if it only holds a single model,
  will use this framework.
  
  Future uses will allowed the Stack gui-container to have all kinds
  of creative animations, beyond what is shown here.

# Creating a single resource in manage

  1. Add any gem dependencies, especially for API fetches.
  - Create a controller that implements at least show. You can render app_container.
    Configure any object retrieval changes.
  - Add routes.
  - Create yourModel.js.coffee.
  - Extend BaseModel with window.YourModel. Specify `urlSuffix`
  with something. Override isNew to be false if you have a singleton model
  - Extend and CrmModelView with window.YourModelView. Specific `modelName`
  in the YourModelView with a *snake case* form of your model. Add any events
  and attach them to buttons as needed.
  - Add to manage.js. If you created this in the manage directory,
  it'll automatically be picked up for you.
  - Insert a bootstrapper in bootDetector.js.coffee.
  - Add to _menu.html.haml, a Feature, feature default generation 0 price.
  - Add controller and model specs.
  - Add background scheduling support.
  - Deploy. Migrate in your feature. Add to default MFE if necessary.
    
# Deploying to production

Cut a release.

    g f release start v1.x

Fix any bugs. Do assets compilation and deploy, if assets have changed.
    
    RAILS_ENV=production rake assets:deploy  # this does an assets:precompile, too.

Commit manifest.

    # whatever your git commit maneuver is
    g add public/assets/manifest.yml
    g ci -m "Updated manifest."
    
Don't mess up your dev machine.

    rake assets:clean
    g co .   # restore old manifest.

Fix any bugs....are you sure? Then finish release.

    g f release finish v1.x
    g push
    
Both dev and master should go upstream.

    cap production deploy:migrations

That's it. If you're sure you don't have migrations:

    cap production deploy

## To restart without deploying:

    cap production unicorn:restart

# Production config

See `doc/server_setup.md`.
