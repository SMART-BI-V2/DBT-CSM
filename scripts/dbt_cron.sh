#!/usr/bin/env bash
# Dựng lại mart CSM trên Doris theo lịch: bọc scripts/dbt_doris.sh với khoá chống chạy chồng,
# log theo ngày và tự xoá log cũ. Biến môi trường (DORIS_PASSWORD, DBT_NETWORK…) xem dbt_doris.sh.
#
# Cài (mỗi 20 phút — role `dbt` của ansible-csm-data cài sẵn trên máy DATA .197):
#   */20 * * * * DBT_NETWORK=host /đường/dẫn/DBT-CSM/scripts/dbt_cron.sh >/dev/null 2>&1
#
# Exit codes:
#   0  build + test đạt, hoặc đang có lần chạy khác giữ khoá
#   1  dbt báo lỗi

set -uo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"
# Trên máy chạy định kỳ: .env (0600, do ansible tạo) chứa DORIS_PASSWORD, DORIS_HOST, DBT_NETWORK…
if [[ -f "$PROJECT_DIR/.env" ]]; then set -a; . "$PROJECT_DIR/.env"; set +a; fi

LOG_DIR="$PROJECT_DIR/logs"
LOCK_FILE="$PROJECT_DIR/.dbt_cron.lock"
LOG_RETENTION_DAYS=30

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/dbt_$(date +%Y%m%d).log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# Bỏ qua thay vì xếp hàng: một lần dựng ~1 phút, chồng lần chạy nghĩa là đang có sự cố.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log "lần chạy khác đang giữ khoá — bỏ qua"
  exit 0
fi

START=$(date +%s)
log "==== dbt build start ===="

# Lần 2 chỉ để dự phòng: đối tác ghi chen ngang lúc đang dựng ⇒ hook on-run-end báo lỗi, dựng lại.
STATUS=1
for attempt in 1 2; do
  if "$PROJECT_DIR/scripts/dbt_doris.sh" build >>"$LOG_FILE" 2>&1; then
    STATUS=0
    log "dbt build OK (lần $attempt, $(( $(date +%s) - START ))s)"
    break
  fi
  log "ERROR: dbt build lỗi (lần $attempt) — xem $LOG_FILE"
  [[ $attempt -eq 1 ]] && sleep 60
done

find "$LOG_DIR" -name 'dbt_*.log' -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null

exit $STATUS
