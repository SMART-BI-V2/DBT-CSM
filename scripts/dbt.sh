#!/usr/bin/env bash
# Run dbt without installing it on the host — everything happens in a container.
#
#   scripts/dbt.sh run                 # build into the production schema `csm`
#   scripts/dbt.sh test
#   scripts/dbt.sh build               # run + test in dependency order
#   scripts/dbt.sh run -s fact_csm_sales
#   TRIAL=1 scripts/dbt.sh run         # build into `csm_dbt` instead, leaving `csm` untouched
#
# The profile is generated on each call from CREDS_ENV (never committed) into a
# gitignored .dbt/ directory, so no password ever lands in the repo.
#
# Connection notes:
#   - The warehouse (casumina_prod) only accepts 127.0.0.1 and 172.28.0.0/16 per
#     its pg_hba.conf, hence --network host + PGHOST=127.0.0.1.
#   - Source tables live in a *different* Postgres and reach dbt through the
#     postgres_fdw foreign schema `public_csm_src`; see dbt_setup_fdw.sql.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DBT_IMAGE="${DBT_IMAGE:-ghcr.io/dbt-labs/dbt-postgres:1.8.2}"
CREDS_ENV="${CREDS_ENV:-/home/smartbi/casumina/casumina-database/.env}"

PGHOST="${PGHOST:-127.0.0.1}"
PGPORT="${PGPORT:-54329}"
PGDATABASE="${PGDATABASE:-casumina_prod}"
PGSCHEMA="${PGSCHEMA:-csm}"
DBT_THREADS="${DBT_THREADS:-4}"

if [[ -z "${PGUSER:-}" || -z "${PGPASSWORD:-}" ]]; then
  [[ -r "$CREDS_ENV" ]] || {
    echo "error: cannot read $CREDS_ENV — set PGUSER/PGPASSWORD or point CREDS_ENV at the env file" >&2
    exit 1
  }
  PGUSER="${PGUSER:-$(grep -oP '(?<=^POSTGRES_USER=).*' "$CREDS_ENV")}"
  PGPASSWORD="${PGPASSWORD:-$(grep -oP '(?<=^POSTGRES_PASSWORD=).*' "$CREDS_ENV")}"
fi

# TRIAL=1 diverts every model to a parallel schema (csm_dbt / staging_csm_dbt)
# so a build can be diffed against production before cutting over.
VARS_ARG=()
if [[ "${TRIAL:-0}" == "1" ]]; then
  VARS_ARG=(--vars "{csm_schema_suffix: ${TRIAL_SUFFIX:-_dbt}}")
  echo ">> TRIAL mode: building into ${PGSCHEMA}${TRIAL_SUFFIX:-_dbt}, production ${PGSCHEMA} untouched"
fi

DBT_HOME="$PROJECT_DIR/.dbt"
mkdir -p "$DBT_HOME/.dbt"
umask 077
cat > "$DBT_HOME/.dbt/profiles.yml" <<EOF
casumina_csm:
  target: dev
  outputs:
    dev:
      type: postgres
      host: $PGHOST
      port: $PGPORT
      user: $PGUSER
      password: '$PGPASSWORD'
      dbname: $PGDATABASE
      schema: $PGSCHEMA
      threads: $DBT_THREADS
      sslmode: prefer
EOF

dbt_docker() {
  docker run --rm --network host \
    -u "$(id -u):$(id -g)" \
    -v "$PROJECT_DIR":/usr/app \
    -v "$DBT_HOME":/dbthome \
    -e HOME=/dbthome \
    -e DBT_PROFILES_DIR=/dbthome/.dbt \
    -w /usr/app \
    "$DBT_IMAGE" "$@"
}

# Fetch packages once; dbt_utils is required to parse the project.
if [[ ! -d "$PROJECT_DIR/dbt_packages/dbt_utils" ]]; then
  echo ">> installing packages (dbt deps)"
  dbt_docker deps
fi

dbt_docker "$@" "${VARS_ARG[@]}"
