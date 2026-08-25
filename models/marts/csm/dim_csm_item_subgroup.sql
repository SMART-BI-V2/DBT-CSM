{{ config(tags=['csm']) }}

select "Code"::text as subgroup_code, "Description"::text as subgroup_name from {{ ref('stg_csm__item_subgroup_1') }}
