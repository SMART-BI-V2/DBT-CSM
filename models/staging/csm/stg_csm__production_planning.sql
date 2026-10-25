{{ config(tags=['staging']) }}

select {{ csm_code('`ItemNo`') }} as `ItemNo`, `PostingDate`,
  `QuantityInput`, `ValueInput`, `QuantityOutput`, `ValueOutput`, `QuantityInland`, `QuantityExport`,
  CAST(`SystemDate` AS DATE) as `SystemDate`
from {{ source('csm', 'production_planning') }}
