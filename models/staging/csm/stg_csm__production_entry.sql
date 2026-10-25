{{ config(tags=['staging']) }}

select {{ csm_code('`ItemNo`') }} as `ItemNo`, `PostingDate`,
  `QuantityBegin`, `ValueBegin`, `QuantityInput`, `ValueInput`, `QuantityInputTotal`, `ValueInputTotal`,
  `QuantityOutput`, `ValueOutput`, `QuantityOutputTotal`, `ValueOutputTotal`,
  `QuantityInland`, `ValueInland`, `QuantityExport`, `ValueExport`, `QuantityEnding`, `ValueEnding`,
  CAST(`SystemDate` AS DATE) as `SystemDate`
from {{ source('csm', 'production_entry') }}
