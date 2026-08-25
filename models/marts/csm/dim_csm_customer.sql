{{ config(tags=['csm']) }}

select
  c."CustomerNo"::text as customer_code, c."CustomerName"::text as customer_name, c."CurrencyCode"::text as currency_code,
  c."CustomerTemplateCode"::text as customer_template_code, c."ResponsibilityCenter"::text as responsibility_center,
  rc."Description"::text as center_name, case when c."ResponsibilityCenter" = '21' then 'export' else 'inland' end as customer_type,
  c."City"::text as city, c."Email"::text as email, c."Phone"::text as phone, c."Address"::text as address
from {{ ref('stg_csm__customer') }} c
left join {{ ref('stg_csm__responsibility_center') }} rc on c."ResponsibilityCenter" = rc."Code" 
