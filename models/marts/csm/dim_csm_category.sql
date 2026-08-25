{{ config(tags=['csm']) }}

select
  "Code"::text as category_code,
  "Description"::text as category_name,
  "BriefName"::text as brief_name,
  "InventoryPostingGroup"::text as inventory_posting_group
from {{ ref('stg_csm__item_category') }}
