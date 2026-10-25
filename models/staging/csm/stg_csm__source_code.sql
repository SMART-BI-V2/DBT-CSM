{{ config(tags=['staging']) }}

select `RowID`, {{ csm_trim("`Code`") }} as `Code`, `Description`, `SortName`, `ShowOn`
from {{ source('csm', 'source_code') }}
