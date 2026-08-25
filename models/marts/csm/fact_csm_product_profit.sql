{{ config(tags=['csm']) }}

select
  "SourceCode"::text as factory_code,
  "ItemNo"::text as product_code,
  "DocumentType"::text as doc_type,
  {{ csm_period_columns('"PostingDate"') }},
  sum(coalesce("Quantity",0))::numeric as sale_qty,
  sum(coalesce("SaleActual",0))::numeric as sale_actual,
  sum(coalesce("CostActual",0))::numeric as cost_actual,
  sum(coalesce("BusinessProfit",0))::numeric as gross_profit,
  sum(coalesce("DiscountAmount",0))::numeric as discount_amt,
  sum(coalesce("CostWarranty",0))::numeric as warranty,
  0::numeric as luong, 0::numeric as fuel, 0::numeric as packing, 0::numeric as cppx,
  0::numeric as vl_phu, 0::numeric as repair, 0::numeric as cost_warehouse,
  0::numeric as dien_luc, 0::numeric as party
from {{ ref('stg_csm__manufacturer_profit') }}
group by 1,2,3,4,5
