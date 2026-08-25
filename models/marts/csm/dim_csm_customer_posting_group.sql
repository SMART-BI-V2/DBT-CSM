{{ config(tags=['csm']) }}

select "Code"::text as posting_group_code, "Description"::text as posting_group_name from {{ ref('stg_csm__customer_posting_group') }}
