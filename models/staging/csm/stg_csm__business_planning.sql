{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'business_planning') }}
