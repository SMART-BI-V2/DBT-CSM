{{ config(tags=['staging']) }}

select {{ csm_trim('`Code`') }} as `Code`, `Description`, `BriefName`, `City`, `Address`, `Email`, `Phone`
from {{ source('csm', 'responsibility_center') }}
