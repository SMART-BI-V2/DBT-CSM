{{ config(tags=['csm']) }}

select "Code"::text as department_code, "Description"::text as department_name, "SourceCode"::text as factory_code from {{ ref('stg_csm__department') }}
