{{ config(tags=['staging']) }}

select *
from {{ source('csm', 'item_subgroup_1') }}
