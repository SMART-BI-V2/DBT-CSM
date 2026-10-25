{{ config(tags=['csm'], duplicate_key=['customer_code', 'product_code', 'period_from'], distributed_by=['customer_code']) }}

-- Lãi theo KH × SP. Nguồn thưa: dev chỉ có 12/2022; prod (2025–2026) hiện rỗng.
select
  CAST(`CustomerNo` AS VARCHAR(128)) as customer_code,
  CAST(`ItemNo` AS VARCHAR(128)) as product_code,
  {{ csm_period_columns('`PostingDate`') }},
  CAST(coalesce(`Quantity`, 0) AS DECIMAL(38,10)) as qty,
  CAST(coalesce(`Amount`, 0) AS DECIMAL(38,10)) as amount,
  CAST(coalesce(`DiscountAmount`, 0) AS DECIMAL(38,10)) as discount_amt,
  CAST(coalesce(`VATAmount`, 0) AS DECIMAL(38,10)) as vat_amount,
  CAST(coalesce(`UnitProfit`, 0) AS DECIMAL(38,10)) as unit_profit,
  CAST(coalesce(`Profit`, 0) AS DECIMAL(38,10)) as profit
from {{ ref('stg_csm__customer_profit') }}
