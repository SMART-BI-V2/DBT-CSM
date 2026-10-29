{{ config(tags=['staging']) }}

select {{ csm_trim('`Code`') }} as `Code`, `Description`, {{ csm_trim('`SourceCode`') }} as `SourceCode`
from {{ source('csm', 'hr_department') }}
