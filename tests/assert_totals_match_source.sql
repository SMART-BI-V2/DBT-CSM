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
  select 'product_profit.business_profit', (select sum(business_profit) from {{ ref('fact_csm_product_profit') }}),
         (select sum(`BusinessProfit`) from {{ source('csm', 'manufacturer_profit') }})
  union all
  select 'material.nhap_total', (select sum(val_nhap_total) from {{ ref('fact_csm_material') }}),
         (select sum(`AmountNhapTotal`) from {{ source('csm', 'material_entry') }})
  union all
  select 'customer_balance.amount_lcy', (select sum(amount_lcy) from {{ ref('fact_csm_customer_balance') }}),
         (select sum(`AmountLCY`) from {{ source('csm', 'customer_balance') }})
  union all
  select 'service_invoice.amount', (select sum(amount) from {{ ref('fact_csm_service_invoice') }}),
         (select sum(`Amount`) from {{ source('csm', 'service_invoice') }})
  union all
  select 'company_profit_flat.amount', (select sum(amount) from {{ ref('company_profit_flat') }}),
         (select sum(`Amount`) from {{ source('csm', 'company_profit') }})
  union all
  select 'customer_profit.profit', (select sum(profit) from {{ ref('fact_csm_customer_profit') }}),
         (select sum(`Profit`) from {{ source('csm', 'customer_profit') }})
  union all
  select 'production_plan.val_output', (select sum(val_output) from {{ ref('fact_csm_production_plan') }}),
         (select sum(`ValueOutput`) from {{ source('csm', 'production_planning') }})
)
-- ngưỡng tương đối: mart làm tròn 2 chữ số từng dòng, cộng dồn hàng chục triệu dòng lệch vài đồng
select k, mart, src from chk
where abs(coalesce(mart,0) - coalesce(src,0)) > greatest(1, abs(coalesce(src,0)) * 1e-12)
