{#- Khoá (grain) của bảng không được trùng: unique_combination: {columns: [a, b]} -#}
{% test unique_combination(model, columns) %}
select {{ columns | join(', ') }}, count(*) as n
from {{ model }}
group by {{ columns | join(', ') }}
having count(*) > 1
{% endtest %}
