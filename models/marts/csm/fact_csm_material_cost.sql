{{ config(tags=['csm'], duplicate_key=['factory_code', 'product_code', 'material_code'], distributed_by=['product_code']) }}

-- Chi phí NVL chính theo XN × thành phẩm × vật tư × tháng.
-- qty = SL THÀNH PHẨM đầu ra (không phải SL vật tư); amount = chi phí vật tư (DƯƠNG);
-- unit_cost = đơn giá vật tư. Kiểm: SUM(amount) = −nvlc của fact_csm_product_cost (~99,8% cặp XN×SP×tháng).
-- Nhiều dòng cùng khoá là dòng tách hợp lệ (đơn giá/SL khác nhau) ⇒ cộng.
select
  CAST(`SourceCode` AS VARCHAR(16)) as factory_code,
  CAST(`ProductionBomNo` AS VARCHAR(128)) as product_code,
  CAST(`ItemNo` AS VARCHAR(128)) as material_code,
  CAST(`ProductionBomNo` AS VARCHAR(128)) as bom_no,
  {{ csm_period_columns('`PostingDate`') }},
  CAST(sum(coalesce(`Quantity`, 0)) AS DECIMAL(38,10)) as qty,
  CAST(sum(coalesce(`Amount`, 0)) AS DECIMAL(38,10)) as amount,
  CAST(avg(coalesce(`UnitCost`, 0)) AS DECIMAL(38,10)) as unit_cost
from {{ ref('stg_csm__manufacturer_material_costing') }}
group by 1, 2, 3, 4, 5, 6
