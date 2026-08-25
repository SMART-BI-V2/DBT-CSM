{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'customer_template') }}
