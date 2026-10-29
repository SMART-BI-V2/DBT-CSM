{{ config(tags=['csm', 'intake'], duplicate_key=['period_from'], distributed_by=['ord']) }}

-- Kế hoạch SXKD cấp CÔNG TY (sheet kh_Cty của tệp KHSX tải qua SmartBI) — dạng NGANG, đúng tên cột
-- bảng company_planning bản dev / mapping của DA (instocktotal, instock_dn … export_rad2).
-- Đơn vị cột: ĐN 02, HM 03, BL 07, Radial 06, Radial 2 08, VP 01 (dim_csm_factory).
-- Nhóm cột "TRONG ĐÓ XUẤT KHẨU" của tệp: ở mục Doanh thu là DOANH THU ĐÃ TRỪ CHIẾT KHẤU (ghi chú
-- "DT-CK" trong tệp) ⇒ revenue_after_discount_*; ở các mục khác là xuất khẩu ⇒ export_*.
-- Số giữ nguyên như tệp: giá trị triệu đồng; sản lượng hiện vật NGHÌN (xem cột unit).
{%- set units = [('total', 'total'), ('02', 'dn'), ('03', 'hm'), ('07', 'bl'), ('06', 'rad'), ('08', 'rad2'), ('01', 'vp')] %}
with c as (
  select * from {{ ref('stg_intake__khsx_cell') }} where LOWER(sheet) = 'kh_cty'
)
select
  period_from,
  CAST(period_year AS INT) as planningyear,
  CAST(period_month AS INT) as planningmonth,
  CAST(revision AS INT) as revision,
  CAST(batch_id AS BIGINT) as batch_id,
  CAST(row_ord AS INT) as ord,
  CAST(row_key AS VARCHAR(256)) as category_code,
  CAST(max(row_label) AS VARCHAR(512)) as categoryname,
  CAST(max(section) AS VARCHAR(64)) as section,
  CAST(max(unit) AS VARCHAR(64)) as unit,
{%- for e, s in units %}
  CAST(max(case when measure = 'production' and entity = '{{ e }}' then value_num end) AS DECIMAL(38,6)) as {{ 'instocktotal' if s == 'total' else 'instock_' ~ s }},
{%- endfor %}
{%- for e, s in units %}
  CAST(max(case when measure = 'sales' and entity = '{{ e }}' then value_num end) AS DECIMAL(38,6)) as outstock_{{ s }},
{%- endfor %}
{%- for e, s in units %}
  CAST(max(case when measure = 'export' and entity = '{{ e }}' and COALESCE(section, '') <> 'revenue' then value_num end) AS DECIMAL(38,6)) as export_{{ s }},
{%- endfor %}
{%- for e, s in units %}
  CAST(max(case when measure = 'export' and entity = '{{ e }}' and section = 'revenue' then value_num end) AS DECIMAL(38,6)) as revenue_after_discount_{{ s }},
{%- endfor %}
  CAST(max(uploaded_at) AS DATETIME) as systemdate
from c
group by period_from, period_year, period_month, revision, batch_id, row_ord, row_key
