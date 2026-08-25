{{ config(tags=['csm']) }}

select "Code"::text as customer_template_code, "Description"::text as template_name, "ResponsibilityCenter"::text as responsibility_center, "CustomerPostingGroup"::text as customer_posting_group from {{ ref('stg_csm__customer_template') }}
