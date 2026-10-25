{{ config(tags=['csm'], duplicate_key=['factory_code', 'product_code', 'doc_type'], distributed_by=['product_code']) }}

-- Lãi gộp theo XN × SP × nội địa/xuất khẩu × tháng. Lưu ý nghiệp vụ: ERP ghi gần như toàn bộ
-- dòng lãi ở SourceCode 01 (Văn phòng) ⇒ không dùng để so lãi giữa các xí nghiệp sản xuất.
-- Các cột chi phí con (luong…party) = 0 như bản cũ (nguồn không có chi tiết).
select
  CAST(`SourceCode` AS VARCHAR(16)) as factory_code,
  CAST(`ItemNo` AS VARCHAR(128)) as product_code,
  CAST(`DocumentType` AS VARCHAR(16)) as doc_type,
  {{ csm_period_columns('`PostingDate`') }},
  CAST(sum(case when {{ csm_is_money_in_qty('`Quantity`', '`SaleActual`') }} then 0 else coalesce(`Quantity`, 0) end) AS DECIMAL(38,10)) as sale_qty,
  CAST(sum(coalesce(`SaleActual`, 0)) AS DECIMAL(38,10)) as sale_actual,
  CAST(sum(coalesce(`CostActual`, 0)) AS DECIMAL(38,10)) as cost_actual,
  CAST(sum(coalesce(`BusinessProfit`, 0)) AS DECIMAL(38,10)) as gross_profit,
  CAST(sum(coalesce(`DiscountAmount`, 0)) AS DECIMAL(38,10)) as discount_amt,
  CAST(sum(coalesce(`CostWarranty`, 0)) AS DECIMAL(38,10)) as warranty,
  CAST(0 AS DECIMAL(38,10)) as luong, CAST(0 AS DECIMAL(38,10)) as fuel, CAST(0 AS DECIMAL(38,10)) as packing,
  CAST(0 AS DECIMAL(38,10)) as cppx, CAST(0 AS DECIMAL(38,10)) as vl_phu, CAST(0 AS DECIMAL(38,10)) as `repair`,
  CAST(0 AS DECIMAL(38,10)) as cost_warehouse, CAST(0 AS DECIMAL(38,10)) as dien_luc, CAST(0 AS DECIMAL(38,10)) as party
from {{ ref('stg_csm__manufacturer_profit') }}
group by 1, 2, 3, 4, 5
