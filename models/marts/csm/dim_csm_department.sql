{{ config(tags=['csm'], duplicate_key=['department_code'], distributed_by=['department_code']) }}

select CAST(`Code` AS VARCHAR(64)) as department_code, CAST(`Description` AS VARCHAR(512)) as department_name, CAST(`SourceCode` AS VARCHAR(16)) as factory_code
from {{ ref('stg_csm__department') }}
