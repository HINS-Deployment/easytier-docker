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
WEB_DEFAULT_API_HOST=${WEB_DEFAULT_API_HOST:-http://127.0.0.1:$WEB_PORT}
WEB_GEOIP_PATH=${WEB_GEOIP_PATH:-}
WEB_LOG_LEVEL=${WEB_LOG_LEVEL:-error}
ALLOW_AUTO_CREATE_USER=${ALLOW_AUTO_CREATE_USER:-false}

# OIDC Configuration
OIDC_ISSUER_URL=${OIDC_ISSUER_URL:-}
OIDC_CLIENT_ID=${OIDC_CLIENT_ID:-}
OIDC_CLIENT_SECRET=${OIDC_CLIENT_SECRET:-}
OIDC_REDIRECT_URL=${OIDC_REDIRECT_URL:-}
OIDC_USERNAME_CLAIM=${OIDC_USERNAME_CLAIM:-}
OIDC_SCOPES=${OIDC_SCOPES:-}
OIDC_DISABLE_PKCE=${OIDC_DISABLE_PKCE:-false}
OIDC_FRONTEND_BASE_URL=${OIDC_FRONTEND_BASE_URL:-}

WEB_DATA_DIR=/app/data/web
WEB_LOG_DIR=/app/data/logs-web

# Custom entrypoint command
if [ "$#" -gt 0 ]; then
  if [ "${1#-}" = "$1" ]; then
    log "[Web] Custom command detected: $*"
    exec "$@"
  fi
fi

log "[Web] Starting easytier-web-embed..."

# Ensure directories exist
mkdir -p "$WEB_DATA_DIR"
mkdir -p "$WEB_LOG_DIR"

# Get API URL
if [[ "$WEB_DEFAULT_API_HOST" == http* ]]; then
  API_URL="$WEB_DEFAULT_API_HOST"
else
  # Assume it's just an IP/Host, append port and scheme
  API_URL="http://$WEB_DEFAULT_API_HOST:$WEB_PORT"
fi

log "[Web] Using API URL: $API_URL"

WEB_ARGS=(
  -d "$WEB_DATA_DIR/et.db"
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

if [ "$ALLOW_AUTO_CREATE_USER" = "true" ]; then
  WEB_ARGS+=(--allow-auto-create-user)
fi

# OIDC Configuration
if [ -n "$OIDC_ISSUER_URL" ]; then
  WEB_ARGS+=(--oidc-issuer-url "$OIDC_ISSUER_URL")
fi

if [ -n "$OIDC_CLIENT_ID" ]; then
  WEB_ARGS+=(--oidc-client-id "$OIDC_CLIENT_ID")
fi

if [ -n "$OIDC_REDIRECT_URL" ]; then
  WEB_ARGS+=(--oidc-redirect-url "$OIDC_REDIRECT_URL")
fi

if [ -n "$OIDC_USERNAME_CLAIM" ]; then
  WEB_ARGS+=(--oidc-username-claim "$OIDC_USERNAME_CLAIM")
fi

if [ -n "$OIDC_SCOPES" ]; then
  WEB_ARGS+=(--oidc-scopes "$OIDC_SCOPES")
fi

if [ "$OIDC_DISABLE_PKCE" = "true" ]; then
  WEB_ARGS+=(--oidc-disable-pkce)
fi

if [ -n "$OIDC_FRONTEND_BASE_URL" ]; then
  WEB_ARGS+=(--oidc-frontend-base-url "$OIDC_FRONTEND_BASE_URL")
fi

log "[Web] Executing command: $(format_cmd easytier-web-embed "${WEB_ARGS[@]}")"

# Export OIDC_CLIENT_SECRET if set (for environment variable support)
if [ -n "$OIDC_CLIENT_SECRET" ]; then
  export OIDC_CLIENT_SECRET
fi

exec easytier-web-embed "${WEB_ARGS[@]}"
