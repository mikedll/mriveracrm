
Please pay a fee to use this software. The fee you pay
can be negotiated and setup at [www.mriveracrm.com](http://www.mriveracrm.com).
You can contact me by email at mrivera@michaelriveraco.com.

Michael Rivera, also known as Mike De La Loza, Owner

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

Nginx is configured at `/etc/nginx/nginx.conf`:

    worker_processes 1;

    user nobody nogroup; # for systems with a "nogroup"

    pid /var/run/nginx.pid;
    error_log /var/log/nginx.error.log;

    events {
      worker_connections 1024; # increase if you have lots of clients
      accept_mutex off; # "on" if nginx worker_processes > 1
      use epoll; # enable for Linux 2.6+
      # use kqueue; # enable for FreeBSD, OSX
    }

    http {
      # nginx will find this file in the config directory set at nginx build time
      include mime.types;

      # fallback in case we can't determine a type
      default_type application/octet-stream;

      # click tracking!
      access_log /var/log/nginx.access.log combined;

      # you generally want to serve static files with nginx since neither
      # Unicorn nor Rainbows! is optimized for it at the moment
      sendfile on;

      tcp_nopush on; # off may be better for *some* Comet/long-poll stuff
      tcp_nodelay off; # on may be better for some Comet/long-poll stuff

      # we haven't checked to see if Rack::Deflate on the app server is
      # faster or not than doing compression via nginx.  It's easier
      # to configure it all in one place here for static files and also
      # to disable gzip for clients who don't get gzip/deflate right.
      # There are other gzip settings that may be needed used to deal with
      # bad clients out there, see http://wiki.nginx.org/NginxHttpGzipModule
      gzip on;
      gzip_http_version 1.0;
      gzip_proxied any;
      gzip_min_length 500;
      gzip_disable "MSIE [1-6]\.";
      gzip_types text/plain text/html text/xml text/css
                 text/comma-separated-values
                 text/javascript application/x-javascript
                 application/atom+xml;

      # this can be any application server, not just Unicorn/Rainbows!
      upstream app_server {
        # fail_timeout=0 means we always retry an upstream even if it failed
        # to return a good HTTP response (in case the Unicorn master nukes a
        # single worker for timing out).

        # for UNIX domain socket setups:
        server unix:/home/mrmike/mikedllcrm/current/tmp/sockets/unicorn.sock fail_timeout=0;
      }

      server {
        # enable one of the following if you're on Linux or FreeBSD
        listen 80 default deferred; # for Linux
        # listen 80 default accept_filter=httpready; # for FreeBSD
        client_max_body_size 4G;
        server_name _;

        keepalive_timeout 5;

        root /home/mrmike/mikedllcrm/current/public;
        try_files $uri/index.html $uri.html $uri @app;

        location @app {
          proxy_set_header  X-Real-IP       $remote_addr;
          proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header  Host $http_host;
          proxy_redirect    off;
          proxy_pass        http://app_server;
        }

        # Rails error pages
        error_page 500 502 503 504 /500.html;
        location = /500.html {
          root /home/mrmike/mikedllcrm/current/public;
        }
      }

      # For SSL configuration, see nginx config in config/nginx.conf.
    }
    
Dependencies: 

    # nginx
    sudo apt-get install nginx

    # xhtml2pdf
    sudo apt-get install python-dev python-pip
    sudo pip install Pillow xhtml2pdf


Certificates are in: `/etc/ssl/private/mikedll.{crt,key}`.  If you
have intermediate certificates, append those after your
certificates. They make a difference in efficiency computation for the
SSL handshake and certificate authentication negotiation.

# SSL DH Group

    > openssl dhparam -out dhparams.pem 2048 
    > sudo mv dhparams.pem /etc/ssl/private/

# Backups

Schedule `config/deploy/cron.sh` on the serer.
