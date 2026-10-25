{{ config(tags=['staging']) }}

select {{ csm_trim('`SourceCode`') }} as `SourceCode`, {{ csm_code('`ItemNo`') }} as `ItemNo`, `PostingDate`,
  `Quantity`, `CostUnit`, `CostActual`, `CostTotal`,
  `MainMaterial`, `SubMaterial`, `Fuel`, `Packing`, `OtherMaterial`, `Engine`, `Salary`,
  `Warranty`, `Party`, `Discount`, `Repair`, `CostWarehouse`
from {{ source('csm', 'manufacturer_costing') }}
