{{ config(tags=['staging']) }}

select {{ csm_trim('`Code`') }} as `Code`, `Description`, {{ csm_trim('`ItemCategoryCode`') }} as `ItemCategoryCode`
from {{ source('csm', 'product_group') }}
