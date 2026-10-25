{{ config(tags=['staging']) }}

select {{ csm_code('`CustomerNo`') }} as `CustomerNo`, {{ csm_code('`ItemNo`') }} as `ItemNo`, {{ csm_trim('CAST(`DocumentType` AS VARCHAR(16))') }} as `DocumentType`,
  `DocumentNo`, {{ csm_trim('`ResponsibilityCenter`') }} as `ResponsibilityCenter`, `PostingDate`,
  `Quantity`, `Amount`, `VATBaseAmount`, `VATAmount`, `LineDiscountAmount`
from {{ source('csm', 'sale_invoice') }}
