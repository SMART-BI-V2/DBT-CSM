{{ config(tags=['staging']) }}

select {{ csm_code('`ProductionBomNo`') }} as `ProductionBomNo`, {{ csm_code('`ItemNo`') }} as `ItemNo`, `PostingDate`,
  `Quantity`, `Scrap`, `GrossWeight`
from {{ source('csm', 'production_bom_line') }}
