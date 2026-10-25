{{ config(tags=['staging']) }}

select {{ csm_trim('`Code`') }} as `Code`, `Description`
from {{ source('csm', 'location') }}
