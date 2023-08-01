FROM python:3.11-alpine3.18

RUN set -ex \
	&& apk add --no-cache tini \
	&& apk add --no-cache \
		aria2 \
	&& pip install --no-cache-dir \
		bypy==1.8 \
	&& true

ADD root/ /
VOLUME ["/root/.bypy"]

ENV RUN_CRONTAB=
ENTRYPOINT ["/run.sh"]
