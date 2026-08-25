{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'company_profit') }}
