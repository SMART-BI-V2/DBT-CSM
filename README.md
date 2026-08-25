# dbt project — Casumina CSM

This dbt project replaces the SQL transforms that were previously embedded in
`scripts/import_csm_to_smartbi.py`. The Python script handled two jobs:

1. **Ingest** raw rows from the operational CSM DB (`casumina_db`) into
   `casumina_prod` (a.k.a. SmartBI).
2. **Transform** each source table into the dimensional model that BI agents
   query (`csm.*`).

dbt now does job (2). Job (1) is a one-way database copy that stays in Python
because Postgres cannot run cross-database `SELECT` from dbt's connection. The
copy is exposed to dbt via a `postgres_fdw` foreign schema so the dbt models
can be written against familiar `{{ source('csm', 'table_name') }}` references
without a network round-trip.

## Prerequisites

- Python 3.10+
- dbt-core 1.8+ with the `dbt-postgres` adapter
- Access to `casumina_prod` (target) and to `casumina_db` (FDW source)

## First-time setup (one-time, in `casumina_prod`)

```sql
-- Run as a superuser, see scripts/dbt_setup_fdw.sql for the full script.
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE SERVER csm_src FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host '<CSM_DB_HOST>', port '<CSM_DB_PORT>', dbname 'casumina_db');
CREATE USER MAPPING FOR CURRENT_USER
  SERVER csm_src OPTIONS (user '<CSM_DB_USER>', password '<CSM_DB_PASSWORD>');
IMPORT FOREIGN SCHEMA public
  FROM SERVER csm_src INTO public_csm_src;
```

After the foreign schema exists, `dbt run` reads the source tables through it
and materialises the marts into the `csm` schema of `casumina_prod`.

## Daily workflow

`scripts/dbt.sh` runs dbt inside a container, so nothing needs installing on the
host. It generates the profile from the warehouse env file on every call, so no
password lives in the repo.

```bash
cd dbt_project
./scripts/dbt.sh build            # run + test in dependency order
./scripts/dbt.sh run              # build the marts into `csm`
./scripts/dbt.sh test
./scripts/dbt.sh run -s fact_csm_sales+   # one model and everything downstream

# Build into `csm_dbt` / `staging_csm_dbt` instead, leaving production alone.
# Use this to diff a change against the live marts before cutting over.
TRIAL=1 ./scripts/dbt.sh run
```

Overridable via environment: `PGHOST` `PGPORT` `PGDATABASE` `PGSCHEMA` `PGUSER`
`PGPASSWORD` `CREDS_ENV` `DBT_IMAGE` `DBT_THREADS` `TRIAL` `TRIAL_SUFFIX`.

The warehouse only accepts connections from `127.0.0.1` and `172.28.0.0/16`
(its `pg_hba.conf`), which is why the script connects over loopback with
`--network host`. The FDW link in the other direction uses the LAN address.

The `postgres_fdw` source tables query the CSM database directly, so no separate
ingestion refresh is needed once the foreign schema is configured. The legacy
`scripts/import_csm_to_smartbi.py` is *not* part of this workflow — it recreates
`csm.*` tables from scratch.

## Layout

```
dbt_project/
  dbt_project.yml
  profiles.yml.example
  packages.yml
  models/
    staging/
      csm/_csm__sources.yml
      csm/stg_csm__*.sql      -- 1:1 with CSM source tables, renaming
      csm/stg_csm__*.yml      -- tests + docs for each staging model
    marts/
      csm/_csm__models.yml    -- tests + docs for each mart
      csm/dim_csm_*.sql       -- dimension tables
      csm/fact_csm_*.sql      -- fact tables
  macros/
    period_from_to.sql        -- DATE_TRUNC helper
    generate_schema_name.sql  -- pins marts to `csm`; honours TRIAL suffix
  scripts/
    dbt.sh                    -- containerised dbt runner (see above)
    dbt_setup_fdw.sql         -- one-time foreign-schema setup
  seeds/                      -- reserved (currently unused)
  snapshots/                  -- reserved (currently unused)
```

## Conventions

- All staging models are views against the foreign schema and use snake_case.
- All marts are tables and live in schema `csm` (matching the legacy output).
- `period_from` / `period_to` are computed via a shared macro.
- Numeric columns are `numeric(18,4)` for qty, `numeric(18,2)` for amounts —
  the same precision used by the legacy ETL.
