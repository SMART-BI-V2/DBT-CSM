{{ config(tags=['csm'], duplicate_key=['product_code'], distributed_by=['product_code']) }}

-- Một bảng, hai vai trò: thành phẩm (product_code ở các fact) và vật tư/NVL/BTP (material_code).
select
  CAST(i.`ItemNo` AS VARCHAR(128)) as product_code,
  CAST(i.`ItemName` AS VARCHAR(2048)) as product_name,
  CAST(i.`UOM` AS VARCHAR(64)) as uom,
  CAST(i.`ItemCategoryCode` AS VARCHAR(64)) as category_code,
  CAST(ic.`Description` AS VARCHAR(512)) as category_name,
  CAST(i.`InventoryPostingGroup` AS VARCHAR(64)) as inventory_posting_group,
  CAST(i.`ProductGroupCode` AS VARCHAR(64)) as product_group_code,
  CAST(pg.`Description` AS VARCHAR(512)) as product_group_name,
  CAST(i.`SubGroupCode1` AS VARCHAR(64)) as sub_group_code1
from {{ ref('stg_csm__item') }} i
left join {{ ref('stg_csm__item_category') }} ic on i.`ItemCategoryCode` = ic.`Code`
left join {{ ref('stg_csm__product_group') }} pg on i.`ProductGroupCode` = pg.`Code`
