{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'sale_invoice') }}
