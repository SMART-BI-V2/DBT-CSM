{#- Ghi đè macro của dbt-doris: xoá bảng bằng FORCE. Mỗi lần dựng (20 phút/lần) dbt xoá 26 bảng tạm/cũ của
    chính nó; DROP thường đẩy chúng vào thùng rác Doris (giữ 1 ngày) ⇒ ~1.900 bảng rác/ngày, tốn đĩa và
    metadata FE. Chỉ áp cho quan hệ dbt quản lý trong CSDL đích. -#}
{% macro doris__drop_relation(relation) -%}
  {% if relation is not none %}
    {% set relation_type = relation.type if relation.type else 'table' %}
    {% call statement('drop_relation', auto_begin=False) %}
      drop {{ relation_type }} if exists {{ relation }}{{ ' force' if relation_type == 'table' else '' }}
    {% endcall %}
  {% endif %}
{%- endmacro %}
