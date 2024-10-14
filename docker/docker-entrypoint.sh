#!/bin/bash
set -e

# set HOME explicitly
export HOME=/root

# wait for rabbitmq, redis, and ES
/wait-for-it.sh -t 30 mozart-rabbitmq:15672
/wait-for-it.sh -t 30 mozart-redis:6379
/wait-for-it.sh -t 30 mozart-elasticsearch:9200

# get group id
GID=$(id -g)

# generate ssh keys
gosu 0:0 ssh-keygen -A 2>/dev/null

if [ -e /var/run/docker.sock ]; then
  gosu 0:0 chown -R $UID:$GID /var/run/docker.sock 2>/dev/null || true
fi

# source bash profile
source $HOME/.bash_profile

# source mozart virtualenv
if [ -e "$HOME/mozart/bin/activate" ]; then
  source $HOME/mozart/bin/activate
fi

# ensure db for mozart_job_management exists
if [ ! -d "$HOME/mozart/ops/mozart/data" ]; then
  mkdir -p $HOME/mozart/ops/mozart/data
fi
if [ -e `readlink $HOME/mozart/ops/mozart/settings.cfg` ]; then
  $HOME/mozart/ops/mozart/db_create.py
fi

# create user rules index
$HOME/mozart/ops/mozart/scripts/create_user_rules_index.py || :

# install ES templates for HySDS package indexes
$HOME/mozart/ops/hysds_commons/scripts/install_es_template.sh mozart || :

if [[ "$#" -eq 1  && "$@" == "supervisord" ]]; then
  set -- supervisord -n
else
  if [ "${1:0:1}" = '-' ]; then
    set -- supervisord "$@"
  fi
fi

exec gosu $UID:$GID "$@"
