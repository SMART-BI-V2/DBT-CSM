{{ config(tags=['csm'], duplicate_key=['customer_template_code'], distributed_by=['customer_template_code']) }}

select
  CAST(`Code` AS VARCHAR(64)) as customer_template_code,
  CAST(`Description` AS VARCHAR(512)) as template_name,
  CAST(`ResponsibilityCenter` AS VARCHAR(64)) as responsibility_center,
  CAST(`CustomerPostingGroup` AS VARCHAR(64)) as customer_posting_group
from {{ ref('stg_csm__customer_template') }}
