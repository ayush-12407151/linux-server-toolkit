#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    log "INFO" "Running in dry-run mode — no changes will be made"
fi

log "INFO" "Starting backup"
mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date '+%Y-%m-%d_%H%M%S')"
ARCHIVE_NAME="backup-$TIMESTAMP.tar.gz"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"

log "INFO" "Backing up: ${BACKUP_SOURCES[*]}"
log "INFO" "Destination: $ARCHIVE_PATH"

if [[ "$DRY_RUN" == true ]]; then
    log "INFO" "[DRY RUN] Would run: tar -czf $ARCHIVE_PATH ${BACKUP_SOURCES[*]}"
else
    if tar -czf "$ARCHIVE_PATH" "${BACKUP_SOURCES[@]}"; then
        log "INFO" "Archive created: $ARCHIVE_PATH"
    else
        notify "Backup FAILED: could not create archive $ARCHIVE_NAME"
        exit 1
    fi

    if tar -tzf "$ARCHIVE_PATH" > /dev/null 2>&1; then
        log "INFO" "Archive verified OK"
    else
        notify "Backup FAILED: archive $ARCHIVE_NAME is corrupt"
        exit 1
    fi

    ARCHIVE_SIZE="$(du -h "$ARCHIVE_PATH" | cut -f1)"
    log "INFO" "Archive size: $ARCHIVE_SIZE"
fi

log "INFO" "Applying retention policy: deleting backups older than $RETENTION_DAYS days"
if [[ "$DRY_RUN" == true ]]; then
    find "$BACKUP_DIR" -name "backup-*.tar.gz" -mtime "+$RETENTION_DAYS" -print | while read -r old; do
        log "INFO" "[DRY RUN] Would delete: $old"
    done
else
    find "$BACKUP_DIR" -name "backup-*.tar.gz" -mtime "+$RETENTION_DAYS" -print -delete | while read -r old; do
        log "INFO" "Deleted old backup: $old"
    done
fi

log "INFO" "Backup complete"
notify "Backup completed successfully: $ARCHIVE_NAME"
