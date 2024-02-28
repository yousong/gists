FROM alpine:3.18 as builder
ARG RARLINUX_TARGZ=rarlinux-x64-624.tar.gz
ARG RARLINUX_TARGZ_MD5SUM=cd34890687cbbc0177fbaf6c9de20449
RUN set -ex \
	&& cd / \
	&& wget --no-check-certificate https://www.rarlab.com/rar/$RARLINUX_TARGZ \
	&& echo "$RARLINUX_TARGZ_MD5SUM  $RARLINUX_TARGZ" | md5sum -c \
	&& tar xzf "$RARLINUX_TARGZ"

FROM debian:bookworm
COPY --from=builder /rar /rar
ENV PATH="/rar:${PATH}"
RUN rar
