{{ config(tags=['csm']) }}

select "Code"::text as responsibility_center, "Description"::text as center_name, "BriefName"::text as brief_name, "City"::text as city, "Address"::text as address from {{ ref('stg_csm__responsibility_center') }}
