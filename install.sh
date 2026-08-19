#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CRON_JOBS="0 2 * * * $PROJECT_ROOT/bin/backup.sh
0 3 * * * $PROJECT_ROOT/bin/log_cleanup.sh
*/15 * * * * $PROJECT_ROOT/bin/service_monitor.sh
*/10 * * * * $PROJECT_ROOT/bin/disk_alert.sh"

( crontab -l 2>/dev/null | grep -v "$PROJECT_ROOT/bin/" ; echo "$CRON_JOBS" ) | crontab -
echo "Cron jobs installed:"
crontab -l
