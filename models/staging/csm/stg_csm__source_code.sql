{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'source_code') }}
