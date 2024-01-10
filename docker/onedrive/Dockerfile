# -*-Dockerfile-*-

ARG DEBIAN_VERSION=stable
ARG GIT_REPO=https://github.com/yousong/onedrive.git
ARG GIT_BRANCH=v2.4-yousong
ARG ENTRYPOINT_URL=https://github.com/yousong/onedrive/raw/${GIT_BRANCH}/contrib/docker/entrypoint.sh

FROM debian:${DEBIAN_VERSION} AS builder-onedrive

RUN apt-get clean \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential curl ca-certificates libcurl4-openssl-dev libsqlite3-dev libxml2-dev pkg-config git ldc \
 && rm -rf /var/lib/apt/lists/*

ARG GIT_REPO
ARG GIT_BRANCH
RUN set -ex \
	&& mkdir -p /usr/src \
	&& cd /usr/src \
	&& git clone "${GIT_REPO}" \
	&& cd onedrive \
	&& git checkout "${GIT_BRANCH}"
WORKDIR /usr/src/onedrive

RUN ./configure DC=/usr/bin/ldmd2 \
 && make clean \
 && make \
 && make install

FROM debian:${DEBIAN_VERSION}-slim

RUN apt-get clean \
 && apt-get update \
 && apt-get upgrade -y \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gosu libcurl4 libsqlite3-0 ca-certificates libphobos2-ldc-shared100 \
 && rm -rf /var/lib/apt/lists/* \
 # Fix bug with ssl on armhf: https://serverfault.com/a/1045189
 && /usr/bin/c_rehash \
 && mkdir -p /onedrive/conf /onedrive/data

COPY --from=builder-onedrive /usr/local/bin/onedrive /usr/local/bin/

ARG ENTRYPOINT_URL
ADD $ENTRYPOINT_URL /
RUN chmod a+x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
