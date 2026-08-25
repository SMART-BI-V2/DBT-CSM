{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'production_entry') }}
