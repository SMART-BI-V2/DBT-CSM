{{ config(tags=['csm'], duplicate_key=['location_code'], distributed_by=['location_code']) }}

select CAST(`Code` AS VARCHAR(64)) as location_code, CAST(`Description` AS VARCHAR(512)) as location_name
from {{ ref('stg_csm__location') }}
