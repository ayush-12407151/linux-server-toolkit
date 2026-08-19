# Linux Server Automation Toolkit

A collection of Bash scripts for common Linux server maintenance tasks: backups, log cleanup, service monitoring, and disk usage alerts.

## Structure
- `bin/` — the four executable scripts
- `lib/common.sh` — shared logging, config loading, alert notifications, and lockfile handling
- `config/toolkit.conf.example` — copy to `toolkit.conf` and edit for your server
- `logs/` — runtime logs (one per script), gitignored
- `install.sh` — installs all four scripts into cron
- `.github/workflows/shellcheck.yml` — CI lint on every push

## Setup


## Scripts
- `backup.sh` — tar/gzip archive of configured source paths, integrity-verified, with retention-based rotation
- `log_cleanup.sh` — compresses logs past a "compress" age threshold, deletes compressed logs past a longer "delete" threshold
- `service_monitor.sh` — checks configured systemd services, attempts one restart on failure, alerts if still down
- `disk_alert.sh` — checks disk usage per mount against warning/critical thresholds

Every script supports `--dry-run` to preview actions without making changes, and logs to `logs/<script>.log`.

## Design decisions
- All multi-value config settings (source paths, services, directories) are Bash **arrays**, not space-separated strings — `common.sh` sets `IFS=$'\n\t'` for filename safety, which would otherwise break naive space-splitting of a plain string.
- Alerts go through a shared `notify()` function that logs locally and optionally posts to a webhook (Slack/Discord), configured via `WEBHOOK_URL`.
- A `flock`-based lockfile in `common.sh` stops cron from ever running two instances of the same script concurrently.
