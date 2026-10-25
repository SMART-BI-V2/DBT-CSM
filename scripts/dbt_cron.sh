#!/usr/bin/env bash
# Dựng lại mart CSM trên Doris theo lịch: bọc scripts/dbt_doris.sh với khoá chống chạy chồng,
# log theo ngày và tự xoá log cũ. Biến môi trường (DORIS_PASSWORD, DBT_NETWORK…) xem dbt_doris.sh.
#
# Cài (mỗi giờ, phút 15):
#   15 * * * * DBT_NETWORK=host /đường/dẫn/DBT-CSM/scripts/dbt_cron.sh >/dev/null 2>&1
#
# Exit codes:
#   0  build + test đạt, hoặc đang có lần chạy khác giữ khoá
#   1  dbt báo lỗi

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

# Bỏ qua thay vì xếp hàng: một lần dựng ~1 phút, chồng lần chạy nghĩa là đang có sự cố.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log "another run holds the lock, skipping"
  exit 0
fi

START=$(date +%s)
log "==== dbt build start ===="

if "$PROJECT_DIR/scripts/dbt_doris.sh" build >>"$LOG_FILE" 2>&1; then
  STATUS=0
  log "dbt build OK (took $(( $(date +%s) - START ))s)"
else
  STATUS=1
  log "ERROR: dbt build failed. See $LOG_FILE"
fi

find "$LOG_DIR" -name 'dbt_*.log' -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null

exit $STATUS
