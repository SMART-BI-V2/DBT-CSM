{{ config(tags=['csm'], duplicate_key=['factory_code'], distributed_by=['factory_code']) }}

select
  CAST(`Code` AS VARCHAR(16)) as factory_code,
  CAST(`Description` AS VARCHAR(512)) as factory_name,
  CAST(`SortName` AS VARCHAR(256)) as brief_name,
  CAST(`ShowOn` AS INT) as show_on
from {{ ref('stg_csm__source_code') }}
