
Please pay a fee to use this software. The fee you pay
can be negotiated and setup at [www.mriveracrm.com](http://www.mriveracrm.com).
You can contact me by email at mrivera@michaelriveraco.com.

Michael Rivera, also known as Mike De La Loza, Owner

# Development setup

See `doc/server_setup.md`.

Run specs with Guard:

    > ./script/fine_grained_daemon.rb # you may have to start the FineGrained daemon.
    > guard
    
Start everyting:

    > foreman start
    
Start server:

    > rails s

Start resque worker

    > bundle exec resque work

# Modules

Model modules are for designated sociopathic boundaries between
applications.

Higher-level marketing front ends may use models from modules, but
it's unlikely that lower-level marketing front ends will use models
from the root namespace. This is not decided, however.

Controller modules are for security restrictions around roles.  We do
not mirror model namespaces in controllers.

# Backgrounded work

We left redis due to the BSD-license, the meaning of which I don't
know.

For job queueing, we have the FineGrained database built
on event machine. The interface for designing classes
that will receive jobs from this queueing system is like
resque, and is as follows:

    class MyClass
      def self.perform
        # do work
      end
    end

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

# Creating Features

  1. Add any gem dependencies, especially for API fetches.
  
  - Create a controller with the `configure_apps` call and specify the
  model while doing so. Define member_actions, and belongs_to.  Define
  the methods `object_parameters`, `parent_object`, and
  `_required_business_support`.
  
  `_required_business_support` should respect the feature requirements.
  
  - In the model being managed as a feature, use attr_accessible
  to whitelist attributes for mass-assignment as needed.
  
  - Add routes.
  
  - Create yourModel.js.coffee.
  
  - Extend BaseModel with window.YourModel. Specify `urlSuffix`
  with something. Override isNew to be false if you have a singleton model.
  
  - Extend and CrmModelView with window.YourModelView. Specific `modelName`
  in the YourModelView with a *snake case* form of your model. Add any events
  and attach them to buttons as needed.
  
  - If you're making a collection, make the containing app. Extend
  CollectionAppView with a singular camel case prefix
  `MyModelCollectionAppView`.  Define properties `modelName`
  (underscored), `modelNamePlural` (underscored), `spawnListItemType`
  (klass), and a `title` method.  Extend ListItemView and define
  `modelName` (underscored), `spawnViewType` (klass), `className`
  (dasherized), and a `title` method. `className` should include the
  css class `list-item`.
  
  - Extend Collection with a pluralized name of your model while defining
  `model` with the model klass and urlFragment with the relative
  url where this app will be served.
  
  - Add to manage.js. If you created this in the manage directory,
  it'll automatically be picked up for you.
  
  - Add to bootDetector.js.coffee. You must specify two things,
  the initializing klasses, and the Javascript variable name where
  the seed may be found when lazily bootstrapping the app.
  Regardless of whether you are making a singular or plural
  multiplicity app, you must specify `rootAppViewKlass`. Then,
  you must also add either `modelKlass` and `modelViewKlass` in the
  case of a singular multiplicity app, or, `modelCollectionKlass`
  in the case of a plural multiplicity app.

  - Add to _menu.html.haml, a Feature, feature default generation 0 price.
  
  - Add controller and model specs.
  
  - Add background scheduling support.
  
  - Deploy. Migrate in your feature. Add to default MFE if necessary.
    
# Deploying to production

Cut a release.

    g f release start v1.x

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

    g f release finish v1.x
    g push
    
Both dev and master should go upstream.

    cap production deploy:migrations

That's it. If you're sure you don't have migrations:

    cap production deploy

# Backups

Check backups capture:

    cknifeaws afew mikedllcrm-backups --count=150 

# Specs

Start a test copy of the FineGrained database in another
process when running specs:

    ./script/fine_grained_daemon.rb db/fineGrainedTest.db

## To restart without deploying:

    cap production unicorn:restart

# Production config

See `doc/server_setup.md`.

# Troubleshooting

## uninitialized constant Invoice::Worker

This was caused by backgrounded workers
that were not cleaned up in the past, and that
were running older versions of the Rails environment.

Another symptom was that you could see workers
in the Resque web worker list, two more beyond
what was obvious to us from foreman invocations.

Killing these other workers stopped the queue
from being depleted by old workers. They had
to be killed at the command line.

## undefined method `const_defined?' for "business":String

Sometimes this happens in a controller when referring
to a model. Use :: module global qualifier.

## missing translations in model class-level code

Not all translation files, namely those outside of our application,
are loaded in time for model definition. The initializer
`config/i18n_preload_paths.rb` addresses this issue for the main
application translation files in config/locales. Gem locales may need
to be looked up and loaded early in a similar fashion.

