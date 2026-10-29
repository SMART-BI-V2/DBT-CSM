{{ config(tags=['csm', 'intake'], duplicate_key=['period_from'], distributed_by=['ord']) }}

-- Kế hoạch SXKD cấp CÔNG TY dạng DỌC: mỗi dòng = chỉ tiêu × nhóm đo × đơn vị — tiện vẽ cơ cấu /
-- tỷ trọng theo đơn vị. measure: production (sản xuất), sales (tiêu thụ), export (xuất khẩu),
-- revenue_after_discount (mục Doanh thu: nhóm cột "trong đó xuất khẩu" của tệp = DT đã trừ CK).
with c as (
  select * from {{ ref('stg_intake__khsx_cell') }} where LOWER(sheet) = 'kh_cty' and value_num is not null
)
select
  c.period_from,
  CAST(c.period_year AS INT) as planningyear,
  CAST(c.period_month AS INT) as planningmonth,
  CAST(c.revision AS INT) as revision,
  CAST(c.row_ord AS INT) as ord,
  CAST(c.row_key AS VARCHAR(256)) as category_code,
  CAST(c.row_label AS VARCHAR(512)) as categoryname,
  CAST(c.section AS VARCHAR(64)) as section,
  CAST(c.unit AS VARCHAR(64)) as unit,
  CAST(case when c.measure = 'export' and c.section = 'revenue' then 'revenue_after_discount' else c.measure end AS VARCHAR(32)) as measure,
  CAST(c.entity AS VARCHAR(16)) as entity_code,
  CAST(case when c.entity = 'total' then 'Toàn công ty' else COALESCE(f.factory_name, c.entity) end AS VARCHAR(256)) as entity_name,
  CAST(c.value_num AS DECIMAL(38,6)) as value
from c
left join {{ ref('dim_csm_factory') }} f on f.factory_code = c.entity
