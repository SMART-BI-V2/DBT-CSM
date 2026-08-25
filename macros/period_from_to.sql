{% macro csm_period_columns(posting_date) -%}
    date_trunc('month', {{ posting_date }})::date as period_from,
    (date_trunc('month', {{ posting_date }}) + interval '1 month - 1 day')::date as period_to
{%- endmacro %}
