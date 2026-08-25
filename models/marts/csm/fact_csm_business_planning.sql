{{ config(tags=['csm']) }}

select
  {{ csm_period_columns('"PostingDate"') }}, 'plan'::text as source,
  max("Kind")::integer as kind,
  sum(coalesce("IndustrialValue",0))::numeric(18,2) as industrial_value,
  sum(coalesce("IndustrialValueActual",0))::numeric(18,2) as industrial_value_actual,
  sum(coalesce("Amount",0))::numeric(18,2) as amount,
  sum(coalesce("IndustrialAmount",0))::numeric(18,2) as industrial_amount,
  sum(coalesce("InlandAmount",0))::numeric(18,2) as inland_amount,
  sum(coalesce("ExportAmount",0))::numeric(18,2) as export_amount,
  0::numeric(18,2) as btp,
  sum(coalesce("BusinessAmount",0))::numeric(18,2) as business_amount,
  max("Worker")::integer as worker,
  sum(coalesce("Salary",0))::numeric(18,2) as salary,
  sum(coalesce("ProfitAmount",0))::numeric(18,2) as profit_amount
from {{ ref('stg_csm__business_planning') }}
group by 1,2,3
union all
select
  {{ csm_period_columns('"PostingDate"') }}, 'actual'::text as source, 0::integer as kind,
  sum(coalesce("IndustrialValue",0))::numeric(18,2),
  sum(coalesce("IndustrialValueActual",0))::numeric(18,2),
  sum(coalesce("Amount",0))::numeric(18,2),
  sum(coalesce("IndustrialAmount",0))::numeric(18,2),
  sum(coalesce("InlandAmount",0))::numeric(18,2),
  sum(coalesce("ExportAmount",0))::numeric(18,2),
  sum(coalesce("BTP",0))::numeric(18,2),
  sum(coalesce("BusinessAmount",0))::numeric(18,2),
  max("Worker")::integer,
  sum(coalesce("Salary",0))::numeric(18,2),
  sum(coalesce("ProfitAmount",0))::numeric(18,2)
from {{ ref('stg_csm__business_planning_actual') }}
group by 1,2,3
