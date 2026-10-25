{{ config(tags=['staging']) }}

select {{ csm_trim('`SourceCode`') }} as `SourceCode`, {{ csm_code('`ItemNo`') }} as `ItemNo`, {{ csm_trim('`DocumentType`') }} as `DocumentType`, `PostingDate`,
  `Quantity`, `SaleActual`, `CostActual`, `BusinessProfit`, `DiscountAmount`, `CostWarranty`
from {{ source('csm', 'manufacturer_profit') }}
