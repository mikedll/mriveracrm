#!/bin/bash

source "$HOME/.rvm/scripts/rvm";

rvm use 2.0.0;

cd $HOME/mikedllcrmbackups;

cknifepg capture;

cknifeaws upsync mikedllcrm-backups . --noprompt --backups-retain --glob="db*.dump";

