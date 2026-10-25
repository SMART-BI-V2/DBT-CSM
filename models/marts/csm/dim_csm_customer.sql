{{ config(tags=['csm'], duplicate_key=['customer_code'], distributed_by=['customer_code']) }}

select
  CAST(c.`CustomerNo` AS VARCHAR(128)) as customer_code,
  CAST(c.`CustomerName` AS VARCHAR(2048)) as customer_name,
  CAST(c.`CurrencyCode` AS VARCHAR(16)) as currency_code,
  CAST(c.`CustomerTemplateCode` AS VARCHAR(64)) as customer_template_code,
  CAST(c.`ResponsibilityCenter` AS VARCHAR(64)) as responsibility_center,
  CAST(rc.`Description` AS VARCHAR(512)) as center_name,
  -- Trung tâm 21 = khách xuất khẩu (giữ quy tắc của mart cũ)
  CAST(case when c.`ResponsibilityCenter` = '21' then 'export' else 'inland' end AS VARCHAR(16)) as customer_type,
  CAST(c.`City` AS VARCHAR(512)) as city,
  CAST(c.`Email` AS VARCHAR(512)) as email,
  CAST(c.`Phone` AS VARCHAR(256)) as phone,
  CAST(c.`Address` AS VARCHAR(2048)) as address
from {{ ref('stg_csm__customer') }} c
left join {{ ref('stg_csm__responsibility_center') }} rc on c.`ResponsibilityCenter` = rc.`Code`
