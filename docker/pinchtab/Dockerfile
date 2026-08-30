# Stage 1: Build the React dashboard with Bun.
FROM oven/bun:1 AS dashboard
WORKDIR /build
COPY dashboard/package.json dashboard/bun.lock ./
RUN bun install --frozen-lockfile
COPY dashboard/ .
RUN bun run build

# Stage 2: Compile the Go binary.
FROM golang:1.26-alpine AS builder
RUN apk add --no-cache git
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
COPY --from=dashboard /build/dist/ internal/dashboard/dashboard/
RUN mv internal/dashboard/dashboard/index.html internal/dashboard/dashboard/dashboard.html
RUN go build -ldflags="-s -w" -o pinchtab ./cmd/pinchtab

# Stage 3: Runtime image with VNC support for headed Chrome.
# Based on jlesage/baseimage-gui which provides X11 + VNC + web interface.
FROM jlesage/baseimage-gui:alpine-3.23-v4

LABEL org.opencontainers.image.source="https://github.com/pinchtab/pinchtab"
LABEL org.opencontainers.image.description="Browser automation bridge with VNC for headed mode"

RUN apk upgrade --no-cache --available \
    && apk add --no-cache \
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

COPY --from=builder /build/pinchtab /usr/local/bin/pinchtab
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
