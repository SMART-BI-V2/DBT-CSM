-- Run once as a casumina_prod database administrator.
-- Replace placeholders with secure values; do not commit credentials.
create extension if not exists postgres_fdw;
create schema if not exists public_csm_src;
create server if not exists csm_src foreign data wrapper postgres_fdw
  options (host '<CSM_DB_HOST>', port '<CSM_DB_PORT>', dbname 'casumina_db');
create user mapping if not exists for current_user server csm_src
  options (user '<CSM_DB_USER>', password '<CSM_DB_PASSWORD>');
import foreign schema public from server csm_src into public_csm_src;
grant usage on foreign server csm_src to <DBT_ROLE>;
grant usage on schema public_csm_src to <DBT_ROLE>;
grant select on all tables in schema public_csm_src to <DBT_ROLE>;
create schema if not exists csm;
grant usage, create on schema csm to <DBT_ROLE>;
