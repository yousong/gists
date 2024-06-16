# -*-Dockerfile-*-

ARG GIT_REPO=https://github.com/yousong/onedriver.git
ARG GIT_BRANCH=yousong


FROM golang:1-alpine3.18 AS builder
RUN apk add git

ARG GIT_REPO
ARG GIT_BRANCH
RUN set -ex \
	&& mkdir -p /usr/src \
	&& cd /usr/src \
	&& git clone "${GIT_REPO}" \
	&& cd onedriver \
	&& git checkout "${GIT_BRANCH}"
WORKDIR /usr/src/onedriver

RUN apk add \
	bash \
	grep \
	make
RUN make onedriver-headless


FROM alpine:3.18
COPY --from=builder /usr/src/onedriver/onedriver-headless /usr/bin/
ENTRYPOINT ["/usr/bin/onedriver-headless"]
