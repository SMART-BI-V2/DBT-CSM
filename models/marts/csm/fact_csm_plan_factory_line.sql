{{ config(tags=['csm', 'intake'], duplicate_key=['period_from'], distributed_by=['factory_code']) }}

-- Dòng NHÓM và dòng TỔNG HỢP của kế hoạch xí nghiệp (sheet kh_xn*): nhóm sản phẩm (vd "Lốp Xe
-- Máy", "Nhóm Tubeless" — tương ứng ERP planning_manu_total, sản lượng chiếc) và chỉ tiêu tổng
-- hợp (I.a giá trị SXCN, II.a/II.b doanh thu chưa/đã chiết khấu — triệu đồng; III lao động – tiền lương).
with c as (
  select * from {{ ref('stg_intake__khsx_cell') }} where LOWER(sheet) like 'kh_xn%' and row_kind in ('group', 'summary')
)
select
  period_from,
  CAST(period_year AS INT) as planningyear,
  CAST(period_month AS INT) as planningmonth,
  CAST(revision AS INT) as revision,
  CAST(entity AS VARCHAR(16)) as factory_code,
  CAST(max(row_kind) AS VARCHAR(16)) as line_kind,
  CAST(min(row_ord) AS INT) as ord,
  CAST(row_key AS VARCHAR(256)) as line_code,
  CAST(max(row_label) AS VARCHAR(512)) as line_name,
  CAST(max(case when measure = 'begin_stock' then value_num end) AS DECIMAL(38,6)) as begin_stock,
  CAST(max(case when measure = 'production' then value_num end) AS DECIMAL(38,6)) as instock,
  CAST(max(case when measure = 'sales_total' then value_num end) AS DECIMAL(38,6)) as outstock,
  CAST(max(case when measure = 'export' then value_num end) AS DECIMAL(38,6)) as outstock_export,
  CAST(max(case when measure = 'inland' then value_num end) AS DECIMAL(38,6)) as outstock_inland,
  CAST(max(case when measure = 'ending_stock' then value_num end) AS DECIMAL(38,6)) as ending_stock
from c
group by period_from, period_year, period_month, revision, entity, row_key
