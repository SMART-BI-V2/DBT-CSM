{{ config(tags=['staging']) }}

select {{ csm_trim('`SourceCode`') }} as `SourceCode`, {{ csm_code('`ProductionBomNo`') }} as `ProductionBomNo`, {{ csm_code('`ItemNo`') }} as `ItemNo`,
  `PostingDate`, `Quantity`, `Amount`, `UnitCost`
from {{ source('csm', 'manufacturer_material_costing') }}
