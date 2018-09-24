FROM hysds/dev:latest

# git url to hysds dev puppet module
ENV GIT_URL https://github.com/hysds/puppet-mozart/raw/docker/install.sh

# add latest repo version to invalidate cache
ADD https://api.github.com/repos/hysds/puppet-mozart/git/refs/heads/docker version.json

# provision via puppet
RUN set -ex \
 && sudo yum update -y \
 && sudo curl -skL ${GIT_URL} > /tmp/install.sh \
 && sudo chmod 755 /tmp/install.sh \
 && sudo /tmp/install.sh \
 && sudo rm -rf /etc/puppet/modules/* /mnt/swapfile \
 && sudo yum clean all \
 && sudo rm -f /tmp/install.sh \
 && sudo rm -rf /var/cache/yum \
 && cd $HOME \
 && ./install_hysds.sh \
 && rm -rf $HOME/mozart/ops/*/.git* \
 && rm -rf $HOME/.cache


FROM hysds/base:latest

MAINTAINER Gerald Manipon (pymonger) "pymonger@gmail.com"
LABEL description="HySDS mozart image"

# git url to hysds dev puppet module
ENV GIT_URL https://github.com/hysds/puppet-mozart/raw/docker/install.sh

# add latest repo version to invalidate cache
ADD https://api.github.com/repos/hysds/puppet-mozart/git/refs/heads/docker version.json

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

# link celeryconfig
RUN set -ex \
 && ln -sf /home/ops/mozart/etc/celeryconfig.py /home/ops/mozart/ops/hysds/celeryconfig.py \
 && ln -sf /home/ops/mozart/etc/settings.cfg /home/ops/mozart/ops/mozart/settings.cfg \
 && ln -sf /home/ops/mozart/etc/settings.cfg /home/ops/mozart/ops/figaro/settings.cfg \
 && ln -sf /home/ops/mozart/etc/server.key /home/ops/mozart/ops/mozart/server.key \
 && ln -sf /home/ops/mozart/etc/server.pem /home/ops/mozart/ops/mozart/server.pem

# set entrypoint
COPY docker/wait-for-it.sh /wait-for-it.sh
COPY docker/docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 80 443 5555 8888 8898 9001
CMD ["supervisord"]
