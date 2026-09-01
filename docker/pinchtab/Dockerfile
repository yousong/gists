ARG PINCHTAB_VERSION=0.15.2

# Runtime image with VNC support for headed Chrome.
# Based on jlesage/baseimage-gui which provides X11 + VNC + web interface.
FROM jlesage/baseimage-gui:alpine-3.23-v4
ARG PINCHTAB_VERSION
ARG TARGETARCH

LABEL org.opencontainers.image.source="https://github.com/pinchtab/pinchtab"
LABEL org.opencontainers.image.description="Browser automation bridge with VNC for headed mode"

RUN apk upgrade --no-cache --available \
    && apk add --no-cache \
    libc6-compat \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    font-noto-cjk \
    font-noto-emoji \
    dumb-init \
    socat \
    mesa \
    mesa-dri-gallium \
    mesa-va-gallium \
    intel-media-driver

RUN mkdir -p /data && chmod 777 /data

ADD --chmod=755 https://github.com/pinchtab/pinchtab/releases/download/v${PINCHTAB_VERSION}/pinchtab-linux-${TARGETARCH} /usr/local/bin/pinchtab
COPY --chmod=0755 docker-entrypoint.sh /startapp.sh

ENV HOME=/data \
    XDG_CONFIG_HOME=/data/.config \
    KEEP_APP_RUNNING=1 \
    VNC_RESOLUTION="1920x1080" \
    LIBVA_DRIVERS_PATH=/usr/lib/dri \
    LIBVA_DRIVER_NAME=iHD \
    APP_NAME="PinchTab"

EXPOSE 9867 5900 5800

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD /bin/sh -lc 'pinchtab health >/dev/null' || exit 1
