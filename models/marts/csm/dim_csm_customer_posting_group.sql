{{ config(tags=['csm'], duplicate_key=['posting_group_code'], distributed_by=['posting_group_code']) }}

select CAST(`Code` AS VARCHAR(64)) as posting_group_code, CAST(`Description` AS VARCHAR(512)) as posting_group_name
from {{ ref('stg_csm__customer_posting_group') }}
