{#- Bảo vệ khỏi việc dựng mart giữa lúc đối tác đang xoá + nạp lại raw_stage.
    Dựa vào information_schema.tables.update_time (thời điểm ghi gần nhất của bảng). -#}

{% macro csm_guard_table() -%}
  {{ return(var('csm_guard_schema') ~ '.csm_run_guard_' ~ target.schema) }}
{%- endmacro %}

{% macro csm_source_last_write() -%}
  {%- set sql -%}
    select coalesce(max(update_time), '1970-01-01 00:00:00') as last_write,
           timestampdiff(second, max(update_time), now()) as idle_seconds
    from information_schema.tables
    where table_schema = '{{ var("csm_source_schema") }}'
  {%- endset -%}
  {{ return(run_query(sql).rows[0]) }}
{%- endmacro %}

{% macro csm_wait_for_quiet_source() %}
  {%- if execute and flags.WHICH in ('run', 'build') -%}
    {%- set quiet = var('csm_quiet_seconds') | int -%}
    {%- set max_wait = var('csm_quiet_max_wait') | int -%}
    {%- set ns = namespace(waited=0, row=csm_source_last_write()) -%}
    {%- for _ in range(0, (max_wait // 15) + 1) -%}
      {%- set idle = ns.row[1] if ns.row[1] is not none else 999999 -%}
      {%- if idle < quiet and ns.waited < max_wait -%}
        {{ log("Nguồn " ~ var('csm_source_schema') ~ " vừa được ghi " ~ idle ~ "s trước — chờ yên " ~ quiet ~ "s", info=True) }}
        {%- do run_query("select sleep(15)") -%}
        {%- set ns.waited = ns.waited + 15 -%}
        {%- set ns.row = csm_source_last_write() -%}
      {%- endif -%}
    {%- endfor -%}
    {%- set idle = ns.row[1] if ns.row[1] is not none else 999999 -%}
    {%- if idle < quiet -%}
      {{ exceptions.raise_compiler_error("Nguồn " ~ var('csm_source_schema') ~ " bị ghi liên tục quá " ~ max_wait ~ "s — bỏ lần dựng này") }}
    {%- endif -%}
    {%- do run_query("drop table if exists " ~ csm_guard_table()) -%}
    {%- do run_query("create table " ~ csm_guard_table() ~ " distributed by random buckets 1 properties('replication_num'='1') as select cast('" ~ ns.row[0] ~ "' as datetime) as source_last_write") -%}
  {%- endif -%}
  select 1
{% endmacro %}

{% macro csm_assert_source_unchanged() %}
  {%- if execute and flags.WHICH in ('run', 'build') -%}
    {%- set before = run_query("select cast(source_last_write as string) from " ~ csm_guard_table()).rows[0][0] -%}
    {%- set now_row = csm_source_last_write() -%}
    {%- do run_query("drop table if exists " ~ csm_guard_table()) -%}
    {%- if (now_row[0] | string) != (before | string) -%}
      {{ exceptions.raise_compiler_error("Nguồn " ~ var('csm_source_schema') ~ " bị ghi trong lúc dựng (" ~ before ~ " → " ~ now_row[0] ~ ") — mart có thể lệch kỳ, cần dựng lại") }}
    {%- endif -%}
  {%- endif -%}
  select 1
{% endmacro %}
