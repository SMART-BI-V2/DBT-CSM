{{ config(tags=['csm'], duplicate_key=['category_code'], distributed_by=['category_code']) }}

select
  CAST(`Code` AS VARCHAR(64)) as category_code,
  CAST(`Description` AS VARCHAR(512)) as category_name,
  CAST(`BriefName` AS VARCHAR(256)) as brief_name,
  CAST(`InventoryPostingGroup` AS VARCHAR(64)) as inventory_posting_group
from {{ ref('stg_csm__item_category') }}
