{{ config(severity='warn') }}
-- Chi phí NVL chi tiết (material_cost) phải khớp NVLC của giá thành cho từng XN × SP × tháng
-- có ở cả hai bảng. Dev 2022–2024: 99,8% cặp khớp. Báo các tháng tỷ lệ khớp < 95%.
with pc as (
  select factory_code, product_code, period_from, -sum(nvlc) as nvlc
  from {{ ref('fact_csm_product_cost') }} group by 1, 2, 3
),
mc as (
  select factory_code, product_code, period_from, sum(amount) as amount
  from {{ ref('fact_csm_material_cost') }} group by 1, 2, 3
)
select pc.period_from, count(*) as cap, sum(abs(pc.nvlc - mc.amount) < 1000) as khop
from pc join mc using (factory_code, product_code, period_from)
group by pc.period_from
having sum(abs(pc.nvlc - mc.amount) < 1000) < 0.95 * count(*)
