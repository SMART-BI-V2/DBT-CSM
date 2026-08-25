{{ config(tags=['csm']) }}

with deduped as (
  select distinct on ("PostingDate", "ProductionBomNo", "ItemNo")
    "PostingDate"::date as period_date,
    "ProductionBomNo"::text as product_code,
    "ItemNo"::text as material_code,
    coalesce("Quantity",0)::numeric(18,6) as qty_per_unit,
    coalesce("Scrap",0)::numeric(10,4) as scrap_pct,
    coalesce("GrossWeight",0)::numeric(18,4) as gross_weight
  from {{ ref('stg_csm__production_bom_line') }}
  order by "PostingDate", "ProductionBomNo", "ItemNo", "Scrap" desc
)
select period_date, product_code, material_code, qty_per_unit, scrap_pct, gross_weight
from deduped
