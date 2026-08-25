{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'location') }}
