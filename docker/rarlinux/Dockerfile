FROM alpine:3.18 as builder
ARG RARLINUX_TARGZ=rarlinux-x64-624.tar.gz
ARG RARLINUX_TARGZ_MD5SUM=cd34890687cbbc0177fbaf6c9de20449
RUN set -ex \
	&& cd / \
	&& wget --no-check-certificate https://www.rarlab.com/rar/$RARLINUX_TARGZ \
	&& echo "$RARLINUX_TARGZ_MD5SUM  $RARLINUX_TARGZ" | md5sum -c \
	&& tar xzf "$RARLINUX_TARGZ"

FROM debian:bookworm-slim
ENV \
	PATH="/rar:${PATH}" \
	LANG="en_US.UTF-8"
COPY --from=builder /rar /rar
RUN set -ex \
	&& rar \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		locales \
	&& rm -rf /var/lib/apt/lists/* \
	&& sed -i -r -e 's/# (en_US.UTF-8)/\1/' /etc/locale.gen \
	&& sed -i -r -e 's/# (zh_CN)/\1/' /etc/locale.gen \
	&& locale-gen
