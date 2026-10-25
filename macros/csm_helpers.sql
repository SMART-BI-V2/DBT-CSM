{#- Mã ERP (sản phẩm, vật tư, khách hàng…): bỏ khoảng trắng hai đầu + viết hoa.
    Doris so sánh chuỗi phân biệt hoa/thường (MySQL dev thì không) và nguồn có mã
    như '410khac00152' / '01030291 ' trong khi danh mục ghi '410KHAC00152'. -#}
{% macro csm_code(col) -%}
    UPPER(TRIM({{ col }}))
{%- endmacro %}

{#- Mã danh mục ngắn (xí nghiệp, loại chứng từ, trung tâm…): chỉ bỏ khoảng trắng. -#}
{% macro csm_trim(col) -%}
    TRIM({{ col }})
{%- endmacro %}

{#- Bảng nguồn có thể chưa tồn tại trong raw_stage (vd business_planning): khi đó
    trả về tập rỗng đúng kiểu thay vì làm hỏng cả lần chạy.
    columns: danh sách (tên, kiểu Doris). -#}
{% macro csm_source_or_empty(table_name, columns) -%}
    {%- set rel = adapter.get_relation(database=none, schema=var('csm_source_schema'), identifier=table_name) -%}
    {%- if rel is not none -%}
        SELECT {% for c in columns %}`{{ c[0] }}`{{ ", " if not loop.last }}{% endfor %} FROM {{ rel }}
    {%- else -%}
        SELECT {% for c in columns %}CAST(NULL AS {{ c[1] }}) AS `{{ c[0] }}`{{ ", " if not loop.last }}{% endfor %}
        FROM (SELECT 1 AS d) AS empty_source WHERE 1 = 0
    {%- endif -%}
{%- endmacro %}

{#- Dòng "điều chỉnh tiền" ERP ghi SỐ TIỀN vào cột số lượng (mã giả 2900xx, hàng nhóm 12 "Khác",
    hoá đơn loại 12): |SL| = |giá trị| và khác 0. Đơn giá thật của hàng hoá luôn > 1 ⇒ không nhầm.
    Kiểm trên dev 2022–2024: 15.081/15.081 dòng hoá đơn loại 12, 468 dòng kế hoạch 2900xx. -#}
{% macro csm_is_money_in_qty(qty, value) -%}
    (coalesce({{ qty }}, 0) <> 0 and abs(abs(coalesce({{ qty }}, 0)) - abs(coalesce({{ value }}, 0))) < 1)
{%- endmacro %}
