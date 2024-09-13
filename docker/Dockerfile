# syntax = docker/dockerfile:1.0-experimental
ARG TAG=HC-522-update
FROM hysds/dev:${TAG}

# get org and branch
ARG ORG
ARG BRANCH
ARG FRAMEWORK_BRANCH
ARG BASE_BRANCH

# git url to hysds dev puppet module
ENV GIT_URL https://github.com/${ORG}/puppet-mozart/raw/${BRANCH}/install.sh

# get release to install
ARG HYSDS_RELEASE=develop

# add latest repo version to invalidate cache
ADD https://api.github.com/repos/${ORG}/puppet-mozart/git/refs/heads/${BRANCH} version.json

# provision via puppet
RUN --mount=type=secret,id=git_oauth_token sudo cp /run/secrets/git_oauth_token $HOME/.git_oauth_token \
 && sudo chown root:root $HOME/.git_oauth_token \
 && set -ex \
 && sudo dnf update -y \
 && sudo curl -skL ${GIT_URL} > /tmp/install.sh \
 && sudo chmod 755 /tmp/install.sh \
 && sudo /tmp/install.sh ${ORG} ${BRANCH} ${BASE_BRANCH} \
 && sudo rm -rf /etc/puppetlabs/code/modules/* /mnt/swapfile \
 && sudo dnf clean all \
 && sudo rm -f /tmp/install.sh \
 && sudo rm -rf /var/cache/dnf \
 && cd $HOME \
 && ./install_hysds.sh ${FRAMEWORK_BRANCH} ${HYSDS_RELEASE} \
 && rm -rf $HOME/mozart/ops/*/.git* \
 && rm -rf $HOME/.cache \
 && rm -rf $HOME/.git_oauth_token


FROM hysds/base:${TAG}

MAINTAINER Gerald Manipon (pymonger) "pymonger@gmail.com"
LABEL description="HySDS mozart image"

# get org and branch
ARG ORG
ARG BRANCH
ARG BASE_BRANCH

# git url to hysds dev puppet module
ENV GIT_URL https://github.com/${ORG}/puppet-mozart/raw/${BRANCH}/install.sh

# provision via puppet
RUN set -ex \
 && sudo dnf update -y \
 && sudo curl -skL ${GIT_URL} > /tmp/install.sh \
 && sudo chmod 755 /tmp/install.sh \
 && sudo /tmp/install.sh ${ORG} ${BRANCH} ${BASE_BRANCH} \
 && sudo rm -rf /etc/puppetlabs/code/modules/* /mnt/swapfile \
 && sudo dnf clean all \
 && sudo rm -f /tmp/install.sh \
 && sudo rm -rf /var/cache/dnf

# copy root
COPY --chown=root:root --from=0 /root /root

# link configs
RUN set -ex \
 && ln -sf /root/mozart/etc/celeryconfig.py /root/mozart/ops/hysds/celeryconfig.py \
 && ln -sf /root/mozart/etc/settings.cfg /root/mozart/ops/mozart/settings.cfg \
 && ln -sf /root/mozart/etc/server.key /root/mozart/ops/mozart/server.key \
 && ln -sf /root/mozart/etc/server.pem /root/mozart/ops/mozart/server.pem

# set default supervisord conf and copy includes
COPY --chown=root:root docker/supervisord.conf /root/mozart/etc/supervisord.conf
COPY --chown=root:root docker/conf.d /root/mozart/etc/conf.d

# set entrypoint
COPY docker/wait-for-it.sh /wait-for-it.sh
COPY docker/docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 22 80 443 5555 8888 8898 9001
CMD ["supervisord"]
