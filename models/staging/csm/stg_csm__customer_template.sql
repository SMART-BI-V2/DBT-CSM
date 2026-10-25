{{ config(tags=['staging']) }}

select {{ csm_trim('`Code`') }} as `Code`, `Description`, {{ csm_trim('`ResponsibilityCenter`') }} as `ResponsibilityCenter`, {{ csm_trim('`CustomerPostingGroup`') }} as `CustomerPostingGroup`
from {{ source('csm', 'customer_template') }}
