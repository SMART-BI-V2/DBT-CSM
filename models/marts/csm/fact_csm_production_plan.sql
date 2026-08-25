{{ config(tags=['csm']) }}

select
  "PostingDate"::date as period_date,
  "ItemNo"::text as product_code,
  sum(coalesce("QuantityInput",0))::numeric(18,4) as qty_plan,
  sum(coalesce("ValueInput",0))::numeric(18,2) as val_plan,
  sum(coalesce("QuantityOutput",0))::numeric(18,4) as qty_output,
  sum(coalesce("ValueOutput",0))::numeric(18,2) as val_output,
  sum(coalesce("QuantityInland",0))::numeric(18,4) as qty_inland,
  sum(coalesce("QuantityExport",0))::numeric(18,4) as qty_export
from {{ ref('stg_csm__production_planning') }}
group by 1,2
