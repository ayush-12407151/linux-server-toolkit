#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CONFIG_FILE="${CONFIG_FILE:-$PROJECT_ROOT/config/toolkit.conf}"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
else
    echo "ERROR: config file not found at $CONFIG_FILE" >&2
    exit 1
fi

LOG_DIR="${LOG_DIR:-$PROJECT_ROOT/logs}"
mkdir -p "$LOG_DIR"
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME%.sh}.log"

log() {
    local level="$1"
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

notify() {
    local message="$1"
    log "ALERT" "$message"
    if [[ -n "${WEBHOOK_URL:-}" ]]; then
        curl -s -X POST -H 'Content-Type: application/json' \
            -d "{\"text\": \"[$SCRIPT_NAME] $message\"}" \
            "$WEBHOOK_URL" > /dev/null || log "WARN" "Failed to send webhook notification"
    fi
}

LOCK_FILE="/tmp/${SCRIPT_NAME%.sh}.lock"
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    log "WARN" "Another instance of $SCRIPT_NAME is already running. Exiting."
    exit 1
fi

cleanup() {
    log "INFO" "$SCRIPT_NAME finished"
}
trap cleanup EXIT
