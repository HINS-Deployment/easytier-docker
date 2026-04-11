#!/bin/bash
set -e

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

format_cmd() {
  local cmd=$1
  shift || true
  printf '%s' "$cmd"
  local arg
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
}

# Default values
WEB_ENABLE_REGISTRATION=${WEB_ENABLE_REGISTRATION:-false}
WEB_PORT=${WEB_PORT:-11211}
WEB_SERVER_PORT=${WEB_SERVER_PORT:-22020}
WEB_SERVER_PROTOCOL=${WEB_SERVER_PROTOCOL:-udp}
WEB_DEFAULT_API_HOST=${WEB_DEFAULT_API_HOST:-http://127.0.0.1:$WEB_API_PORT}
WEB_GEOIP_PATH=${WEB_GEOIP_PATH:-}
WEB_LOG_LEVEL=${WEB_LOG_LEVEL:-error}
WEB_DATA_DIR=/app/data/web
WEB_LOG_DIR=/app/data/logs-web

# Custom entrypoint command
if [ "$#" -gt 0 ]; then
  if [ "${1#-}" = "$1" ]; then
    log "[Core] Custom command detected: $*"
    exec "$@"
  fi
fi

# Ensure directory exists
mkdir -p "$WEB_LOG_DIR"

log "[Web] Starting easytier-web-embed..."

# Get API URL
if [[ "$WEB_DEFAULT_API_HOST" == http* ]]; then
  API_URL="$WEB_DEFAULT_API_HOST"
else
  # Assume it's just an IP/Host, append port and scheme
  API_URL="http://$WEB_DEFAULT_API_HOST:$WEB_API_PORT"
fi

log "[Web] Using API URL: $API_URL"

WEB_ARGS=(
  -d "$WEB_DATA_DIR/et.db"
  --console-log-level "$WEB_LOG_LEVEL"
  --file-log-level "$WEB_LOG_LEVEL"
  --file-log-dir "$WEB_LOG_DIR"
  -c "$WEB_SERVER_PORT"
  -a "$WEB_PORT"
  -p "$WEB_SERVER_PROTOCOL"
  --api-host "$API_URL"
)

if [ -n "$WEB_GEOIP_PATH" ]; then
  WEB_ARGS+=("--geoip-db" "$WEB_GEOIP_PATH")
fi

if [ "$WEB_ENABLE_REGISTRATION" = "false" ]; then
  WEB_ARGS+=(--disable-registration)
fi

log "[Web] Executing command: $(format_cmd easytier-web-embed "${WEB_ARGS[@]}")"

exec easytier-web-embed "${WEB_ARGS[@]}"
