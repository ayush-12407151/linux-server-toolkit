#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"

log "INFO" "Starting disk usage check"

df -P | awk 'NR>1 {print $5, $6}' | sed 's/%//' | while read -r usage mount; do
    if [[ "$usage" -ge "$DISK_CRIT_THRESHOLD" ]]; then
        log "ERROR" "CRITICAL: $mount is at ${usage}% (threshold: ${DISK_CRIT_THRESHOLD}%)"
        notify "CRITICAL: $mount is at ${usage}% disk usage"
    elif [[ "$usage" -ge "$DISK_WARN_THRESHOLD" ]]; then
        log "WARN" "$mount is at ${usage}% (threshold: ${DISK_WARN_THRESHOLD}%)"
        notify "WARNING: $mount is at ${usage}% disk usage"
    else
        log "INFO" "$mount is at ${usage}% — OK"
    fi
done

log "INFO" "Disk usage check complete"
