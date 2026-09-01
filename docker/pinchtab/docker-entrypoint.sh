#!/bin/sh
set -eu

home_dir="${HOME:-/data}"
xdg_config_home="${XDG_CONFIG_HOME:-$home_dir/.config}"
default_config_path="$xdg_config_home/pinchtab/config.json"

mkdir -p "$home_dir" "$xdg_config_home" "$(dirname "$default_config_path")"

# Generate a persisted config on first boot.
# The PINCHTAB_TOKEN env var can be used to set an auth token via Docker secrets
# or environment variables. Prefer Docker secrets for sensitive data:
#   docker run -e PINCHTAB_TOKEN_FILE=/run/secrets/pinchtab_token
if [ -z "${PINCHTAB_CONFIG:-}" ] && [ ! -f "$default_config_path" ]; then
  /usr/local/bin/pinchtab config init >/dev/null
  # Docker containers need to bind to 0.0.0.0 for port publishing to work
  /usr/local/bin/pinchtab config set server.bind "0.0.0.0" >/dev/null
  # VNC image defaults to headed mode so the browser is visible in the desktop
  if [ "${PINCHTAB_MODE:-}" = "headed" ]; then
    /usr/local/bin/pinchtab config set instanceDefaults.mode headed >/dev/null
  fi
  if [ -n "${PINCHTAB_TOKEN:-}" ]; then
    /usr/local/bin/pinchtab config set server.token "$PINCHTAB_TOKEN" >/dev/null
  fi
fi

# Default to pinchtab server if no arguments provided
if [ $# -eq 0 ]; then
  set -- pinchtab server
fi

# Redirect stdin from /dev/null for the main process.
# This makes isInteractiveTerminal() return false, so the security wizard
# runs in non-interactive mode instead of blocking waiting for input.
# (jlesage baseimage allocates a TTY, which would otherwise trigger the wizard)
exec "$@" < /dev/null
