{#- Ghi đè dbt-doris 1.0.0: bản gốc ghi cả dict cấu hình cột vào COMMENT (lỗi cú pháp) và không xử lý
    dấu nháy. Ở đây chỉ ghi phần mô tả; nháy đơn đổi thành nháy cong để chuỗi SQL luôn hợp lệ. -#}
{% macro csm_sql_string(text) -%}
  {{- (text or '') | replace("'", "’") | replace('\\', '/') | replace('\n', ' ') -}}
{%- endmacro %}

{% macro doris__alter_column_comment(relation, column_dict) -%}
  {% if relation.type != 'view' %}
    {% for column_name, column in column_dict.items() %}
      {% set text = column['description'] if column is mapping else column %}
      {% if text %}
        {% call statement('alter_column_comment') %}
          alter table {{ relation }} modify column `{{ column_name }}` comment '{{ csm_sql_string(text) }}'
        {% endcall %}
      {% endif %}
    {% endfor %}
  {% endif %}
{%- endmacro %}

{% macro doris__alter_relation_comment(relation, relation_comment) -%}
  {% call statement('alter_relation_comment') %}
    alter table {{ relation }} modify comment '{{ csm_sql_string(relation_comment) }}'
  {% endcall %}
{%- endmacro %}

{% macro doris__table_comment() -%}
  COMMENT '{{ csm_sql_string(model.get('description', '')) }}'
{%- endmacro %}
