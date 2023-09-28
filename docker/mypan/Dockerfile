FROM golang:1-alpine3.18 AS builder

RUN apk add git make
RUN set -x \
	&& git clone https://github.com/yousong/mypan \
	&& cd mypan \
	&& make \
	&& mv mypan /usr/bin/mypan

FROM alpine:3.18

RUN set -ex \
	&& apk add --no-cache tini \
	&& true

COPY --from=builder /usr/bin/mypan /usr/bin/mypan
ADD root/ /
VOLUME ["/root/.mypan"]

ENV RUN_CRONTAB=
ENTRYPOINT ["/run.sh"]
