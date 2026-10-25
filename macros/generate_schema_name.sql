{% macro generate_schema_name(custom_schema_name, node) -%}
    {#-
      Doris: schema = database. Mọi mart (và seed) nằm chung một CSDL đích
      (target.schema — `mart` khi chạy thật, CSDL tmp_* khi thử nghiệm).
    -#}
    {{ target.schema }}
{%- endmacro %}
