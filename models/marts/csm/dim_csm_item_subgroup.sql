{{ config(tags=['csm'], duplicate_key=['subgroup_code'], distributed_by=['subgroup_code']) }}

select CAST(`Code` AS VARCHAR(64)) as subgroup_code, CAST(`Description` AS VARCHAR(512)) as subgroup_name
from {{ ref('stg_csm__item_subgroup_1') }}
