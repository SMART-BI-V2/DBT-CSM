{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'balance_account') }}
