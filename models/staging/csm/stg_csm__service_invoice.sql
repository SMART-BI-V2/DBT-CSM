{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'service_invoice') }}
