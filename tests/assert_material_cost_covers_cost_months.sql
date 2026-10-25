{{ config(severity='warn') }}
-- Cảnh báo dữ liệu đối tác: tháng có giá thành nhưng thiếu chi phí NVL chi tiết
-- (prod 10/2026: chỉ 7/21 tháng có manufacturer_material_costing).
select distinct pc.period_from
from {{ ref('fact_csm_product_cost') }} pc
left join (select distinct period_from from {{ ref('fact_csm_material_cost') }}) mc using (period_from)
where mc.period_from is null
