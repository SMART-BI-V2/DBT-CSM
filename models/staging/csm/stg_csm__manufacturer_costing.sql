{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'manufacturer_costing') }}
