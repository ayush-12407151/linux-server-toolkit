#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    log "INFO" "Running in dry-run mode — no changes will be made"
fi

log "INFO" "Starting service monitor"

for service in "${SERVICES_TO_MONITOR[@]}"; do
    if systemctl is-active --quiet "$service"; then
        log "INFO" "$service is running"
    else
        log "WARN" "$service is DOWN"
        if [[ "$DRY_RUN" == true ]]; then
            log "INFO" "[DRY RUN] Would attempt to restart $service"
        else
            log "INFO" "Attempting to restart $service"
            if sudo systemctl restart "$service"; then
                sleep 2
                if systemctl is-active --quiet "$service"; then
                    log "INFO" "$service restarted successfully"
                    notify "$service was down and has been restarted successfully"
                else
                    log "ERROR" "$service still down after restart attempt"
                    notify "$service is DOWN and restart FAILED — manual intervention needed"
                fi
            else
                log "ERROR" "Failed to run restart command for $service"
                notify "$service is DOWN and restart command failed — manual intervention needed"
            fi
        fi
    fi
done

log "INFO" "Service monitor check complete"
