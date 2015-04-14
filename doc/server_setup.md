
Pick a package directory.

# Redis

Download [Redis 3.0](http://download.redis.io/releases/redis-3.0.0.tar.gz) to your package directory.

    > tar -xzf redis-3.0.0.tar.gz 
    > cd redis-3.0.0/
    > make 
    > make test 
    > sudo make install
    > redis-server -v 
    Redis server v=3.0.0 sha=00000000:0 malloc=jemalloc-3.6.0 bits=64 build=b3c1bfa1b88f43f9

## Setup a config

    > cd [app dir]
    > cp config/redis.conf.sample config/redis.conf

## Start the server, if local

    redis-server ./config/redis.conf

## Cure system for redis. Some comments on our adjusted configuration:

Max clients is down to 4096 to coincide with a Linux setting.

Disable 'Transparent Huge Pages':

    echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled

Allow overcommit memory:

    > sudo vi /etc/sysctl.conf

    vm.overcommit_memory = 1

Max backlog:

    tcp-backlog 128

Which is a Linux default on Ubuntu 12. See the redis config
if you want to raise it.

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

Certificates are in: `/etc/ssl/private/mikedll.{crt,key}`  If you
have intermediate certificates, append those after your
certificates. They make a difference in efficiency computation for the
SSL handshake and certificate authentication negotiation.

# SSL DH Group

    > openssl dhparam -out dhparams.pem 2048 
    > sudo mv dhparams.pem /etc/ssl/private/

# Backups

Schedule `config/deploy/cron.sh` on the serer.
