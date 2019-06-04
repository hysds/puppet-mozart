#!/bin/bash
set -e

# wait for rabbitmq, redis, and ES
/wait-for-it.sh -t 30 mozart-rabbitmq:15672
/wait-for-it.sh -t 30 mozart-redis:6379
/wait-for-it.sh -t 30 mozart-elasticsearch:9200

# get group id
GID=$(id -g)

# generate ssh keys
gosu 0:0 ssh-keygen -A 2>/dev/null

# update user and group ids
gosu 0:0 groupmod -g $GID ops 2>/dev/null
gosu 0:0 usermod -u $UID -g $GID ops 2>/dev/null
gosu 0:0 usermod -aG docker ops 2>/dev/null

# update ownership
gosu 0:0 chown -R $UID:$GID /home/ops 2>/dev/null || true
gosu 0:0 chown -R $UID:$GID /var/run/docker.sock 2>/dev/null || true
gosu 0:0 chown -R $UID:$GID /var/log/supervisor 2>/dev/null || true

# source mozart virtualenv
if [ -e "/home/ops/mozart/bin/activate" ]; then
  source /home/ops/mozart/bin/activate
fi

# ensure db for mozart_job_management exists
if [ ! -d "/home/ops/mozart/ops/mozart/data" ]; then
  mkdir -p /home/ops/mozart/ops/mozart/data
fi
if [ -e `readlink /home/ops/mozart/ops/mozart/settings.cfg` ]; then
  /home/ops/mozart/ops/mozart/db_create.py
fi

# ensure db for figaro exists
if [ ! -d "/home/ops/mozart/ops/figaro/data" ]; then
  mkdir -p /home/ops/mozart/ops/figaro/data
fi
if [ -e `readlink /home/ops/mozart/ops/figaro/settings.cfg` ]; then
  /home/ops/mozart/ops/figaro/db_create.py
fi

# create user rules index
/home/ops/mozart/ops/mozart/scripts/create_user_rules_index.py || :

# install ES templates for HySDS package indexes
/home/ops/mozart/ops/hysds_commons/scripts/install_es_template.sh mozart || :

if [[ "$#" -eq 1  && "$@" == "supervisord" ]]; then
  set -- supervisord -n
else
  if [ "${1:0:1}" = '-' ]; then
    set -- supervisord "$@"
  fi
fi

exec gosu $UID:$GID "$@"
