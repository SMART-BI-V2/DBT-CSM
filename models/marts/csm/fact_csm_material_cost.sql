{{ config(tags=['csm']) }}

select
  "SourceCode"::text as factory_code,
  "ProductionBomNo"::text as product_code,
  "ItemNo"::text as material_code,
  "ProductionBomNo"::text as bom_no,
  {{ csm_period_columns('"PostingDate"') }},
  sum(coalesce("Quantity",0))::numeric as qty,
  sum(coalesce("Amount",0))::numeric as amount,
  avg(coalesce("UnitCost",0))::numeric as unit_cost
from {{ ref('stg_csm__manufacturer_material_costing') }}
group by 1,2,3,4,5,6
