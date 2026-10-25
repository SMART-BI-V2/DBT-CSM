{{ config(tags=['csm'], duplicate_key=['responsibility_center'], distributed_by=['responsibility_center']) }}

select
  CAST(`Code` AS VARCHAR(64)) as responsibility_center,
  CAST(`Description` AS VARCHAR(512)) as center_name,
  CAST(`BriefName` AS VARCHAR(256)) as brief_name,
  CAST(`City` AS VARCHAR(512)) as city,
  CAST(`Address` AS VARCHAR(2048)) as address
from {{ ref('stg_csm__responsibility_center') }}
