{{ config(tags=['staging']) }}

select {{ csm_code('`ItemNo`') }} as `ItemNo`, `ItemName`, `UOM`, {{ csm_trim('`ItemCategoryCode`') }} as `ItemCategoryCode`,
  {{ csm_trim('`InventoryPostingGroup`') }} as `InventoryPostingGroup`, {{ csm_trim('`ProductGroupCode`') }} as `ProductGroupCode`,
  {{ csm_trim('`SubGroupCode1`') }} as `SubGroupCode1`
from {{ source('csm', 'item') }}
