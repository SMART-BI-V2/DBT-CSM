{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'production_bom_line') }}
