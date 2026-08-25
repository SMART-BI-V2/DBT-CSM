{{ config(tags=['csm']) }}

select
  "Code"::text as factory_code,
  "Description"::text as factory_name,
  "SortName"::text as brief_name,
  "ShowOn"::integer as show_on
from {{ ref('stg_csm__source_code') }}
