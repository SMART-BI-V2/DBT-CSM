{{ config(tags=['csm']) }}

select
  "CustomerNo"::text as customer_code,
  "ItemNo"::text as product_code,
  {{ csm_period_columns('"PostingDate"') }},
  coalesce("Quantity",0)::numeric as qty,
  coalesce("Amount",0)::numeric as amount,
  coalesce("DiscountAmount",0)::numeric as discount_amt,
  coalesce("VATAmount",0)::numeric as vat_amount,
  coalesce("UnitProfit",0)::numeric as unit_profit,
  coalesce("Profit",0)::numeric as profit
from {{ ref('stg_csm__customer_profit') }}
