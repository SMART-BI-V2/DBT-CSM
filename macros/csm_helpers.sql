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

{#- Tháng đầu tiên còn SỐ TẠM (chưa khoá sổ) của nhập – xuất – tồn: ERP chỉ tính giá xuất cho sản xuất,
    đánh giá lại tồn… khi khoá sổ tháng — cùng lúc sinh giá thành (manufacturer_costing). Vì vậy:
    tháng tạm = sau tháng giá thành gần nhất, và luôn gồm tháng hiện tại. Trả về biểu thức vô hướng (DATE).
    Ví dụ 25/10/2026: giá thành có tới 09/2026 ⇒ từ 2026-10-01 là số tạm (tháng 10 AmountXuatSX = 0). -#}
{% macro csm_provisional_from() -%}
    (select least(
        coalesce(date_add(max(CAST(DATE_TRUNC(`PostingDate`, 'month') AS DATE)), interval 1 month),
                 CAST(DATE_TRUNC(CURDATE(), 'month') AS DATE)),
        CAST(DATE_TRUNC(CURDATE(), 'month') AS DATE))
     from {{ ref('stg_csm__manufacturer_costing') }})
{%- endmacro %}

{#- Ngày số liệu được tính tới của nguồn chỉ ghi THEO THÁNG (mọi dòng PostingDate = ngày 1: material_entry,
    production_entry, production_planning): ngày ERP trích số (SystemDate) của tháng cuối, chặn ở cuối tháng.
    SystemDate là thời điểm đối tác trích/nạp lại (cả bảng nạp lại mỗi ngày ⇒ tháng cũ cũng mang ngày mới),
    nên chỉ có nghĩa với tháng cuối; ERP không có cột ngày chứng từ thật cho các bảng tổng hợp này.
    Dòng chụp số dư (ngày ≠ 1) bị loại. -#}
{% macro csm_monthly_as_of(rel) -%}
    (select CAST(least(LAST_DAY(max(`PostingDate`)), max(`SystemDate`)) AS DATE)
     from {{ rel }}
     where `PostingDate` = (select max(`PostingDate`) from {{ rel }} where DAY(`PostingDate`) = 1))
{%- endmacro %}
