{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'product_group') }}
