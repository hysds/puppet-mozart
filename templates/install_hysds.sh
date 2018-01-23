#!/bin/bash

MOZART_DIR=<%= @mozart_dir %>


# create virtualenv if not found
if [ ! -e "$MOZART_DIR/bin/activate" ]; then
  virtualenv --system-site-packages $MOZART_DIR
  echo "Created virtualenv at $MOZART_DIR."
fi


# source virtualenv
source $MOZART_DIR/bin/activate


# install latest pip and setuptools
pip install -U pip
pip install -U setuptools


# force install supervisor
if [ ! -e "$MOZART_DIR/bin/supervisord" ]; then
  pip install --ignore-installed supervisor
fi


# create etc directory
if [ ! -d "$MOZART_DIR/etc" ]; then
  mkdir $MOZART_DIR/etc
fi


# create log directory
if [ ! -d "$MOZART_DIR/log" ]; then
  mkdir $MOZART_DIR/log
fi


# create run directory
if [ ! -d "$MOZART_DIR/run" ]; then
  mkdir $MOZART_DIR/run
fi


# set oauth token
OAUTH_CFG="$HOME/.git_oauth_token"
if [ -e "$OAUTH_CFG" ]; then
  source $OAUTH_CFG
  GIT_URL="https://${GIT_OAUTH_TOKEN}@github.com"
else
  GIT_URL="https://github.com"
fi


# create ops directory
OPS="$MOZART_DIR/ops"
if [ ! -d "$OPS" ]; then
  mkdir $OPS
fi


# export latest prov_es package
cd $OPS
PACKAGE=prov_es
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest osaka package
cd $OPS
GITHUB_REPO=osaka
PACKAGE=osaka
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${GITHUB_REPO}.git $PACKAGE
fi
cd $OPS/$PACKAGE
pip install -U pyasn1
pip install -U pyasn1-modules
pip install -U python-dateutil
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest hysds_commons package
cd $OPS
PACKAGE=hysds_commons
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest hysds package
cd $OPS
PACKAGE=hysds
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi
pip install -U  greenlet
pip install -U  pytz
pip uninstall -y celery
cd $OPS/$PACKAGE/third_party/celery-v3.1.25.pqueue
pip install --process-dependency-links -e .
cd $OPS/$PACKAGE
pip install --process-dependency-links -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest sciflo package
cd $OPS
PACKAGE=sciflo
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest mozart package
cd $OPS
PACKAGE=mozart
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest grq2 package
cd $OPS
PACKAGE=grq2
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi


# export latest tosca package
cd $OPS
PACKAGE=tosca
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi


# export latest spyddder-man package
cd $OPS
PACKAGE=spyddder-man
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi
