{{ config(tags=['staging']) }}

select {{ csm_code('`ItemNo`') }} as `ItemNo`, `PostingDate`,
  `QuantityBegin`, `ValueBegin`, `QuantityInput`, `ValueInput`, `QuantityInputTotal`, `ValueInputTotal`,
  `QuantityOutput`, `ValueOutput`, `QuantityOutputTotal`, `ValueOutputTotal`,
  `QuantityInland`, `ValueInland`, `QuantityExport`, `ValueExport`, `QuantityEnding`, `ValueEnding`
from {{ source('csm', 'production_entry') }}
