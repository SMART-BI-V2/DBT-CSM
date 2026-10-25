{{ config(tags=['staging']) }}

select {{ csm_trim('`Code`') }} as `Code`, `Description`, `BriefName`, {{ csm_trim('`InventoryPostingGroup`') }} as `InventoryPostingGroup`
from {{ source('csm', 'item_category') }}
