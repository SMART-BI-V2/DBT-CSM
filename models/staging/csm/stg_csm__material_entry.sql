{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'material_entry') }}
