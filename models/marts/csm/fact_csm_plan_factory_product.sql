{{ config(tags=['csm', 'intake'], duplicate_key=['period_from'], distributed_by=['product_code']) }}

-- Kế hoạch SXKD cấp XÍ NGHIỆP theo SẢN PHẨM (sheet kh_xn* của tệp KHSX) — tương ứng bảng ERP
-- planning_manu_detail (BeginStock, Instock, Outstock, Export, Inland, EndingStock) + giá bán, giá
-- chuẩn, tiền lương đơn vị của tệp. Sản lượng: chiếc; giá/tiền lương: đồng/chiếc.
with c as (
  select * from {{ ref('stg_intake__khsx_cell') }} where LOWER(sheet) like 'kh_xn%' and row_kind = 'item'
)
select
  period_from,
  CAST(period_year AS INT) as planningyear,
  CAST(period_month AS INT) as planningmonth,
  CAST(revision AS INT) as revision,
  CAST(batch_id AS BIGINT) as batch_id,
  CAST(entity AS VARCHAR(16)) as factory_code,
  CAST(row_key AS VARCHAR(128)) as product_code,
  CAST(max(row_label) AS VARCHAR(512)) as product_name,
  CAST(max(case when measure = '_group' then value_text end) AS VARCHAR(256)) as product_group,
  CAST(min(row_ord) AS INT) as ord,
  CAST(max(case when measure = 'begin_stock' then value_num end) AS DECIMAL(38,6)) as begin_stock,
  CAST(max(case when measure = 'production' then value_num end) AS DECIMAL(38,6)) as instock,
  CAST(max(case when measure = 'sales_total' then value_num end) AS DECIMAL(38,6)) as outstock,
  CAST(max(case when measure = 'export' then value_num end) AS DECIMAL(38,6)) as outstock_export,
  CAST(max(case when measure = 'inland' then value_num end) AS DECIMAL(38,6)) as outstock_inland,
  CAST(max(case when measure = 'ending_stock' then value_num end) AS DECIMAL(38,6)) as ending_stock,
  CAST(max(case when measure = 'price' then value_num end) AS DECIMAL(38,6)) as price,
  CAST(max(case when measure = 'std_price' then value_num end) AS DECIMAL(38,6)) as std_price,
  CAST(max(case when measure = 'wage' then value_num end) AS DECIMAL(38,6)) as wage,
  CAST(max(uploaded_at) AS DATETIME) as systemdate
from c
group by period_from, period_year, period_month, revision, batch_id, entity, row_key
