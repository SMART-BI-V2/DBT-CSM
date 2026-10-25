{{ config(tags=['staging']) }}

select {{ csm_code('`ItemNo`') }} as `ItemNo`, `PostingDate`,
  `QuantityInput`, `ValueInput`, `QuantityOutput`, `ValueOutput`, `QuantityInland`, `QuantityExport`
from {{ source('csm', 'production_planning') }}
