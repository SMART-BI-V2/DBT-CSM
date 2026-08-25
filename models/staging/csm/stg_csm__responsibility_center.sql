{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'responsibility_center') }}
