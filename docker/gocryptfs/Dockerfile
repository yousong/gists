FROM golang:1-alpine3.18 AS builder
ARG GOCRYPTFS_VERSION=2.4.0

RUN apk add bash gcc git libc-dev openssl-dev
RUN set -x \
	&& git clone https://github.com/rfjakob/gocryptfs \
	&& cd gocryptfs \
	&& git checkout v$GOCRYPTFS_VERSION
WORKDIR gocryptfs
RUN ./build.bash
RUN mv "$(go env GOPATH)/bin/gocryptfs" /usr/bin/gocryptfs


FROM alpine:3.18
COPY --from=builder /usr/bin/gocryptfs /usr/bin/gocryptfs
ENTRYPOINT ["/usr/bin/gocryptfs"]
