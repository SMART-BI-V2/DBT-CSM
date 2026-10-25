{{ config(tags=['csm'], duplicate_key=['period_from', 'period_to', 'source'], distributed_by=['period_from']) }}

-- Kế hoạch / thực hiện kinh doanh công ty. Nguồn chưa có trong raw_stage ⇒ bảng rỗng đúng cấu trúc.
select
  {{ csm_period_columns('`PostingDate`') }}, CAST('plan' AS VARCHAR(16)) as source,
  CAST(max(`Kind`) AS INT) as kind,
  CAST(sum(coalesce(`IndustrialValue`, 0)) AS DECIMAL(18,2)) as industrial_value,
  CAST(sum(coalesce(`IndustrialValueActual`, 0)) AS DECIMAL(18,2)) as industrial_value_actual,
  CAST(sum(coalesce(`Amount`, 0)) AS DECIMAL(18,2)) as amount,
  CAST(sum(coalesce(`IndustrialAmount`, 0)) AS DECIMAL(18,2)) as industrial_amount,
  CAST(sum(coalesce(`InlandAmount`, 0)) AS DECIMAL(18,2)) as inland_amount,
  CAST(sum(coalesce(`ExportAmount`, 0)) AS DECIMAL(18,2)) as export_amount,
  CAST(0 AS DECIMAL(18,2)) as btp,
  CAST(sum(coalesce(`BusinessAmount`, 0)) AS DECIMAL(18,2)) as business_amount,
  CAST(max(`Worker`) AS INT) as worker,
  CAST(sum(coalesce(`Salary`, 0)) AS DECIMAL(18,2)) as salary,
  CAST(sum(coalesce(`ProfitAmount`, 0)) AS DECIMAL(18,2)) as profit_amount
from {{ ref('stg_csm__business_planning') }}
group by 1, 2, 3
union all
select
  {{ csm_period_columns('`PostingDate`') }}, CAST('actual' AS VARCHAR(16)) as source, CAST(0 AS INT) as kind,
  CAST(sum(coalesce(`IndustrialValue`, 0)) AS DECIMAL(18,2)),
  CAST(sum(coalesce(`IndustrialValueActual`, 0)) AS DECIMAL(18,2)),
  CAST(sum(coalesce(`Amount`, 0)) AS DECIMAL(18,2)),
  CAST(sum(coalesce(`IndustrialAmount`, 0)) AS DECIMAL(18,2)),
  CAST(sum(coalesce(`InlandAmount`, 0)) AS DECIMAL(18,2)),
  CAST(sum(coalesce(`ExportAmount`, 0)) AS DECIMAL(18,2)),
  CAST(sum(coalesce(`BTP`, 0)) AS DECIMAL(18,2)),
  CAST(sum(coalesce(`BusinessAmount`, 0)) AS DECIMAL(18,2)),
  CAST(max(`Worker`) AS INT),
  CAST(sum(coalesce(`Salary`, 0)) AS DECIMAL(18,2)),
  CAST(sum(coalesce(`ProfitAmount`, 0)) AS DECIMAL(18,2))
from {{ ref('stg_csm__business_planning_actual') }}
group by 1, 2, 3
