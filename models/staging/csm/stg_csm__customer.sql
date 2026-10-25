{{ config(tags=['staging']) }}

select {{ csm_code('`CustomerNo`') }} as `CustomerNo`, `CustomerName`, `CurrencyCode`, {{ csm_trim('`CustomerTemplateCode`') }} as `CustomerTemplateCode`,
  {{ csm_trim('`ResponsibilityCenter`') }} as `ResponsibilityCenter`, `City`, `Email`, `Phone`, `Address`
from {{ source('csm', 'customer') }}
