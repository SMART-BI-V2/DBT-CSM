{{ config(tags=['staging']) }}

select {{ csm_trim('`Code`') }} as `Code`, `Description`
from {{ source('csm', 'item_subgroup_1') }}
