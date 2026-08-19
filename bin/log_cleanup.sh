#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    log "INFO" "Running in dry-run mode — no changes will be made"
fi

log "INFO" "Starting log cleanup"

for dir in "${LOG_CLEANUP_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        log "WARN" "Directory does not exist, skipping: $dir"
        continue
    fi

    SPACE_BEFORE="$(du -sh "$dir" 2>/dev/null | cut -f1)"
    log "INFO" "Scanning $dir (currently $SPACE_BEFORE)"

    find "$dir" -type f -name "*.log" -mtime "+$LOG_COMPRESS_DAYS" -print | while read -r file; do
        if [[ "$DRY_RUN" == true ]]; then
            log "INFO" "[DRY RUN] Would compress: $file"
        else
            gzip "$file"
            log "INFO" "Compressed: $file"
        fi
    done

    find "$dir" -type f -name "*.gz" -mtime "+$LOG_DELETE_DAYS" -print | while read -r file; do
        if [[ "$DRY_RUN" == true ]]; then
            log "INFO" "[DRY RUN] Would delete: $file"
        else
            rm -f "$file"
            log "INFO" "Deleted: $file"
        fi
    done

    if [[ "$DRY_RUN" == false ]]; then
        SPACE_AFTER="$(du -sh "$dir" 2>/dev/null | cut -f1)"
        log "INFO" "After cleanup, $dir is now $SPACE_AFTER (was $SPACE_BEFORE)"
    fi
done

log "INFO" "Log cleanup complete"
notify "Log cleanup completed for: ${LOG_CLEANUP_DIRS[*]}"
