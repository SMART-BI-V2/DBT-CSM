{% macro generate_schema_name(custom_schema_name, node) -%}
    {#
      Keep published marts in exactly `csm`, matching the legacy CSM importer.
      Staging models retain their explicit `staging_csm` schema. This avoids
      dbt-postgres's default <target_schema>_<custom_schema> naming.

      `csm_schema_suffix` (default empty) lets a trial run land beside the
      production schemas, e.g. --vars '{csm_schema_suffix: _dbt}' builds into
      `csm_dbt` / `staging_csm_dbt` without touching `csm`.
    #}
    {%- set suffix = var('csm_schema_suffix', '') -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}{{ suffix }}
    {%- else -%}
        {{ custom_schema_name | trim }}{{ suffix }}
    {%- endif -%}
{%- endmacro %}
