{{ config(tags=['staging']) }}

select {{ csm_code('`CustomerNo`') }} as `CustomerNo`, {{ csm_code('`ItemNo`') }} as `ItemNo`, `PostingDate`,
  `Quantity`, `Amount`, `DiscountAmount`, `VATAmount`, `UnitProfit`, `Profit`
from {{ source('csm', 'customer_profit') }}
