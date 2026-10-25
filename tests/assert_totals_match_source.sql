-- Không mất / nhân bản dòng: tổng tiền ở mart = tổng ở nguồn ERP.
with chk as (
  select 'sales.amount' as k, (select sum(amount) from {{ ref('fact_csm_sales') }}) as mart,
         (select sum(`Amount`) from {{ source('csm', 'sale_invoice') }}) as src
  union all
  select 'product_cost.total_cost', (select sum(total_cost) from {{ ref('fact_csm_product_cost') }}),
         (select sum(`CostActual`) from {{ source('csm', 'manufacturer_costing') }})
  union all
  select 'material_cost.amount', (select sum(amount) from {{ ref('fact_csm_material_cost') }}),
         (select sum(`Amount`) from {{ source('csm', 'manufacturer_material_costing') }})
  union all
  select 'product_profit.sale_actual', (select sum(sale_actual) from {{ ref('fact_csm_product_profit') }}),
         (select sum(`SaleActual`) from {{ source('csm', 'manufacturer_profit') }})
  union all
  select 'material.nhap_total', (select sum(val_nhap_total) from {{ ref('fact_csm_material') }}),
         (select sum(`AmountNhapTotal`) from {{ source('csm', 'material_entry') }})
  union all
  select 'customer_balance.amount_lcy', (select sum(amount_lcy) from {{ ref('fact_csm_customer_balance') }}),
         (select sum(`AmountLCY`) from {{ source('csm', 'customer_balance') }})
)
select k, mart, src from chk where abs(coalesce(mart,0) - coalesce(src,0)) > 1
