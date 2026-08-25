{{ config(tags=['csm']) }}

select
  i."ItemNo"::text as product_code, i."ItemName"::text as product_name, i."UOM"::text as uom,
  i."ItemCategoryCode"::text as category_code, ic."Description"::text as category_name,
  i."InventoryPostingGroup"::text as inventory_posting_group, i."ProductGroupCode"::text as product_group_code,
  pg."Description"::text as product_group_name, i."SubGroupCode1"::text as sub_group_code1
from {{ ref('stg_csm__item') }} i
left join {{ ref('stg_csm__item_category') }} ic on i."ItemCategoryCode" = ic."Code"
left join {{ ref('stg_csm__product_group') }} pg on i."ProductGroupCode" = pg."Code" 
