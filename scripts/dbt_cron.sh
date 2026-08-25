#!/usr/bin/env bash
# Rebuild the CSM marts on a schedule. Wraps scripts/dbt.sh with a lock, a
# daily log and retention, mirroring casumina-mysql/auto_sync.sh.
#
# Install (hourly, 15 minutes past — after the */5 MySQL sync has settled):
#   crontab -e
#   15 * * * * /home/smartbi/casumina/dbt_project/scripts/dbt_cron.sh >/dev/null 2>&1
#
# Exit codes:
#   0  build + tests passed, or another run already holds the lock
#   1  dbt reported a failure

set -uo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

LOG_DIR="$PROJECT_DIR/logs"
LOCK_FILE="$PROJECT_DIR/.dbt_cron.lock"
LOG_RETENTION_DAYS=30

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/dbt_$(date +%Y%m%d).log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# Skip rather than queue: a build takes ~15s, so an overlap means something is
# wrong and piling up more runs would only make it worse.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log "another run holds the lock, skipping"
  exit 0
fi

START=$(date +%s)
log "==== dbt build start ===="

if "$PROJECT_DIR/scripts/dbt.sh" build >>"$LOG_FILE" 2>&1; then
  STATUS=0
  log "dbt build OK (took $(( $(date +%s) - START ))s)"
else
  STATUS=1
  log "ERROR: dbt build failed. See $LOG_FILE"
fi

find "$LOG_DIR" -name 'dbt_*.log' -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null

exit $STATUS
