{% macro csm_period_columns(posting_date) -%}
    CAST(DATE_TRUNC({{ posting_date }}, 'month') AS DATE) AS period_from,
    CAST(LAST_DAY({{ posting_date }}) AS DATE) AS period_to
{%- endmacro %}

{% macro csm_month(posting_date) -%}
    CAST(DATE_TRUNC({{ posting_date }}, 'month') AS DATE)
{%- endmacro %}
