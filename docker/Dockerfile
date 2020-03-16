# syntax = docker/dockerfile:1.0-experimental
FROM hysds/dev:latest

# git url to hysds dev puppet module
ENV GIT_URL https://github.com/hysds/puppet-mozart/raw/docker-es7/install.sh

# get release to install
ARG RELEASE=develop-es7

# add latest repo version to invalidate cache
ADD https://api.github.com/repos/hysds/puppet-mozart/git/refs/heads/docker-es7 version.json

# provision via puppet
RUN --mount=type=secret,id=git_oauth_token sudo cp /run/secrets/git_oauth_token $HOME/.git_oauth_token \
 && sudo chown ops:ops $HOME/.git_oauth_token \
 && set -ex \
 && sudo yum update -y \
 && sudo curl -skL ${GIT_URL} > /tmp/install.sh \
 && sudo chmod 755 /tmp/install.sh \
 && sudo /tmp/install.sh \
 && sudo rm -rf /etc/puppet/modules/* /mnt/swapfile \
 && sudo yum clean all \
 && sudo rm -f /tmp/install.sh \
 && sudo rm -rf /var/cache/yum \
 && cd $HOME \
 && ./install_hysds.sh ${RELEASE} \
 && rm -rf $HOME/mozart/ops/*/.git* \
 && rm -rf $HOME/.cache \
 && rm -rf $HOME/.git_oauth_token


FROM hysds/base:latest

MAINTAINER Gerald Manipon (pymonger) "pymonger@gmail.com"
LABEL description="HySDS mozart image"

# git url to hysds dev puppet module
ENV GIT_URL https://github.com/hysds/puppet-mozart/raw/docker-es7/install.sh

# provision via puppet
RUN set -ex \
 && sudo yum update -y \
 && sudo curl -skL ${GIT_URL} > /tmp/install.sh \
 && sudo chmod 755 /tmp/install.sh \
 && sudo /tmp/install.sh \
 && sudo rm -rf /etc/puppet/modules/* /mnt/swapfile \
 && sudo yum clean all \
 && sudo rm -f /tmp/install.sh \
 && sudo rm -rf /var/cache/yum

# copy ops home
COPY --chown=ops:ops --from=0 /home/ops /home/ops

# link configs
RUN set -ex \
 && ln -sf /home/ops/mozart/etc/celeryconfig.py /home/ops/mozart/ops/hysds/celeryconfig.py \
 && ln -sf /home/ops/mozart/etc/settings.cfg /home/ops/mozart/ops/mozart/settings.cfg \
 && ln -sf /home/ops/mozart/etc/settings.cfg /home/ops/mozart/ops/figaro/settings.cfg \
 && ln -sf /home/ops/mozart/etc/server.key /home/ops/mozart/ops/mozart/server.key \
 && ln -sf /home/ops/mozart/etc/server.pem /home/ops/mozart/ops/mozart/server.pem

# set default supervisord conf and copy includes
COPY --chown=ops:ops docker/supervisord.conf /home/ops/mozart/etc/supervisord.conf
COPY --chown=ops:ops docker/conf.d /home/ops/mozart/etc/conf.d

# set entrypoint
COPY docker/wait-for-it.sh /wait-for-it.sh
COPY docker/docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 22 80 443 5555 8888 8898 9001
CMD ["supervisord"]
