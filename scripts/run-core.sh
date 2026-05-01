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
HOSTNAME=${HOSTNAME:-}
CORE_LOG_LEVEL=${CORE_LOG_LEVEL:-error}

CONFIG_DIR=/app/data/config
CORE_LOG_DIR=/app/data/logs-core

# Custom entrypoint command
if [ "$#" -gt 0 ]; then
  if [ "${1#-}" = "$1" ]; then
    log "[Core] Custom command detected: $*"
    exec "$@"
  fi
fi

log "[Core] Starting easytier-core..."

# Ensure directories exist
mkdir -p "$CORE_LOG_DIR"
mkdir -p "$CONFIG_DIR"

CORE_ARGS=(
  --console-log-level "$CORE_LOG_LEVEL"
  --file-log-level "$CORE_LOG_LEVEL"
  --file-log-dir "$CORE_LOG_DIR"
  --file-log-size 30
  --file-log-count 5
  --config-dir "$CONFIG_DIR"
)

if [ -n "$HOSTNAME" ]; then
  CORE_ARGS+=("--hostname" "$HOSTNAME")
fi

# Add machine ID if WEB_REMOTE_API is set (for remote web connection)
if [ -n "$WEB_REMOTE_API" ]; then
  MACHINE_ID_FILE="/app/data/web/et_machine_id"
  mkdir -p "$(dirname "$MACHINE_ID_FILE")"
  if [ ! -f "$MACHINE_ID_FILE" ]; then
      log "[Core] Generating new machine ID..."
      cat /proc/sys/kernel/random/uuid > "$MACHINE_ID_FILE"
  fi
  MACHINE_ID=$(cat "$MACHINE_ID_FILE")
  log "[Core] Using machine ID: $MACHINE_ID"
  CORE_ARGS+=("--machine-id" "$MACHINE_ID")
  CORE_ARGS+=("-w" "$WEB_REMOTE_API")
fi

log "[Core] Executing command: $(format_cmd easytier-core "${CORE_ARGS[@]}")"

exec easytier-core "${CORE_ARGS[@]}"
