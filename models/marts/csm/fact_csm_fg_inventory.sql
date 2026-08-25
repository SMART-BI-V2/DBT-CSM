{{ config(tags=['csm']) }}

select
  "PostingDate"::date as period_date,
  "ItemNo"::text as product_code,
  sum(coalesce("QuantityBegin",0))::numeric(18,4) as qty_begin,
  sum(coalesce("ValueBegin",0))::numeric(18,2) as val_begin,
  sum(coalesce("QuantityInput",0))::numeric(18,4) as qty_input,
  sum(coalesce("ValueInput",0))::numeric(18,2) as val_input,
  sum(coalesce("QuantityOutput",0))::numeric(18,4) as qty_output,
  sum(coalesce("ValueOutput",0))::numeric(18,2) as val_output,
  sum(coalesce("QuantityEnding",0))::numeric(18,4) as qty_ending,
  sum(coalesce("ValueEnding",0))::numeric(18,2) as val_ending,
  sum(coalesce("QuantityInland",0))::numeric(18,4) as qty_inland,
  sum(coalesce("ValueInland",0))::numeric(18,2) as val_inland,
  sum(coalesce("QuantityExport",0))::numeric(18,4) as qty_export,
  sum(coalesce("ValueExport",0))::numeric(18,2) as val_export
from {{ ref('stg_csm__production_entry') }}
group by 1,2
