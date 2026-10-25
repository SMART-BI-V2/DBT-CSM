{{ config(tags=['csm'], duplicate_key=['period_date', 'product_code'], distributed_by=['product_code']) }}

-- Kế hoạch sản xuất theo SP × tháng (toàn công ty); period_date = NGÀY ĐẦU tháng.
-- [SỬA] dòng kế hoạch giảm trừ (mã giả 2900xx…) ERP ghi SỐ TIỀN vào QuantityOutput/QuantityInland
-- (dev 2024: 99,96% "sản lượng kế hoạch" là số tiền) ⇒ không tính vào số lượng; giá trị giữ nguyên.
select
  {{ csm_month('`PostingDate`') }} as period_date,
  CAST(`ItemNo` AS VARCHAR(128)) as product_code,
  CAST(sum(case when is_money then 0 else coalesce(`QuantityInput`,0) end) AS DECIMAL(18,4)) as qty_plan,
  CAST(sum(coalesce(`ValueInput`,0)) AS DECIMAL(18,2)) as val_plan,
  CAST(sum(case when is_money then 0 else coalesce(`QuantityOutput`,0) end) AS DECIMAL(18,4)) as qty_output,
  CAST(sum(coalesce(`ValueOutput`,0)) AS DECIMAL(18,2)) as val_output,
  CAST(sum(case when is_money then 0 else coalesce(`QuantityInland`,0) end) AS DECIMAL(18,4)) as qty_inland,
  CAST(sum(case when is_money then 0 else coalesce(`QuantityExport`,0) end) AS DECIMAL(18,4)) as qty_export
from (
  select p.*, {{ csm_is_money_in_qty('p.`QuantityOutput`', 'p.`ValueOutput`') }} as is_money
  from {{ ref('stg_csm__production_planning') }} p
) x
group by 1, 2
