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

1. Clone the repo onto the target server.
2. Copy the example config and edit it for your server:
   ```
   cp config/toolkit.conf.example config/toolkit.conf
   $EDITOR config/toolkit.conf
   ```
   `config/toolkit.conf` is gitignored — it's never committed, so real paths, service names,
   and (if used) your webhook URL stay local to the server.
3. Confirm the scripts are executable (they're committed with the executable bit set, but
   verify after cloning): `chmod +x bin/*.sh install.sh`
4. Install the cron schedule: `./install.sh`. This installs all four scripts into your user
   crontab (daily backup, daily log cleanup, service check every 15 min, disk check every
   10 min). Re-running `install.sh` is safe — it replaces this project's entries rather than
   duplicating them.
5. `service_monitor.sh` restarts failed services via `sudo systemctl restart`. Since it runs
   unattended from cron, the crontab's user needs **passwordless sudo** for `systemctl`
   (e.g. a `NOPASSWD` sudoers entry scoped to `systemctl restart <service>` for the services
   you're monitoring). Without it, restart attempts will hang/fail under cron.
6. Do a dry run of each script before trusting the schedule: `./bin/backup.sh --dry-run`,
   `./bin/log_cleanup.sh --dry-run`, `./bin/service_monitor.sh --dry-run`,
   `./bin/disk_alert.sh` (read-only, no dry-run flag needed).

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
