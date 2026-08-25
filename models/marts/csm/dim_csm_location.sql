{{ config(tags=['csm']) }}

select "Code"::text as location_code, "Description"::text as location_name from {{ ref('stg_csm__location') }}
