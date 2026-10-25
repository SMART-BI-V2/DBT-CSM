#!/usr/bin/env bash
# Chạy dbt (adapter Doris) trong container — không cài gì lên máy.
#
#   scripts/dbt_doris.sh build                    # run + test, ghi vào CSDL `mart`
#   DBT_TARGET_DB=tmp_x scripts/dbt_doris.sh build # ghi vào CSDL khác (thử nghiệm)
#   scripts/dbt_doris.sh build --vars '{csm_source_schema: tmp_src}'   # đọc nguồn khác raw_stage
#
# Mật khẩu dbt_runner: biến DORIS_PASSWORD, hoặc đọc từ vault ansible-csm-data (VAULT_DIR).
# Mạng: mặc định đi qua container VPN `csm-vpn` (máy dev); chạy trên LAN đối tác thì DBT_NETWORK=host.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DBT_IMAGE="${DBT_IMAGE:-dbt-doris-csm:1.0.0}"
DBT_NETWORK="${DBT_NETWORK:-container:csm-vpn}"
DORIS_HOST="${DORIS_HOST:-192.168.15.197}"
DORIS_PORT="${DORIS_PORT:-9030}"
DORIS_USER="${DORIS_USER:-dbt_runner}"
DBT_TARGET_DB="${DBT_TARGET_DB:-mart}"
DBT_THREADS="${DBT_THREADS:-4}"
VAULT_DIR="${VAULT_DIR:-/data/smartbi-test/ansible-csm-data}"

if [[ -z "${DORIS_PASSWORD:-}" ]]; then
  DORIS_PASSWORD="$(cd "$VAULT_DIR" && ansible-vault view inventory/group_vars/all/vault.yml \
    | python3 -c 'import sys,yaml; print(yaml.safe_load(sys.stdin)["vault_doris_dbt_password"])')"
fi

docker image inspect "$DBT_IMAGE" >/dev/null 2>&1 || docker build -q -t "$DBT_IMAGE" "$PROJECT_DIR/docker"

DBT_HOME="$PROJECT_DIR/.dbt"
mkdir -p "$DBT_HOME"
umask 077
cat > "$DBT_HOME/profiles.yml" <<YML
casumina_csm:
  target: doris
  outputs:
    doris:
      type: doris
      host: $DORIS_HOST
      port: $DORIS_PORT
      username: $DORIS_USER
      password: '$DORIS_PASSWORD'
      schema: $DBT_TARGET_DB
      threads: $DBT_THREADS
YML

docker run --rm --network "$DBT_NETWORK" \
  -u "$(id -u):$(id -g)" \
  -v "$PROJECT_DIR":/usr/app -v "$DBT_HOME":/dbthome \
  -e HOME=/dbthome -e DBT_PROFILES_DIR=/dbthome \
  -w /usr/app "$DBT_IMAGE" "$@"
