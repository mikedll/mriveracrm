#!/bin/bash


# heroku pgbackups:capture HEROKU_POSTGRESQL_BROWN_URL --expire -a mikedll

# wget -O ./tmp/backup.dump `heroku pgbackups:url -a mikedll`

dropdb -U mikedllcrmdev -W mikedllcrm_prodmirror

createdb -U mikedllcrmdev -W mikedllcrm_prodmirror

pg_restore -c -i --no-owner -h localhost -p 5432 -U mikedllcrmdev -d mikedllcrm_prodmirror -v "./tmp/backup.dump"

rake prodrefresh:update_importantMar2015

rake db:migrate

rake prodrefresh:clear_sensitive

rake prodrefresh:update_importantMar2015_2




