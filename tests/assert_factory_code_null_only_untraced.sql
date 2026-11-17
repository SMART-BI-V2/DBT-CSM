-- factory_code của kế hoạch / nhập–xuất–tồn thành phẩm chỉ được NULL khi SP CHƯA TỪNG có giá thành
-- (không có dấu vết xí nghiệp nào). SP đã có giá thành mà vẫn NULL ⇒ hỏng logic gán
-- (vd lệch kiểu/chuẩn hoá mã khi join dim_csm_product_factory).
select 'fact_csm_production_plan' as tbl, p.product_code, count(*) as n_rows
from {{ ref('fact_csm_production_plan') }} p
join (select distinct product_code from {{ ref('fact_csm_product_cost') }}) c
  on c.product_code = p.product_code
where p.factory_code is null
group by 1, 2
union all
select 'fact_csm_fg_inventory', p.product_code, count(*)
from {{ ref('fact_csm_fg_inventory') }} p
join (select distinct product_code from {{ ref('fact_csm_product_cost') }}) c
  on c.product_code = p.product_code
where p.factory_code is null
group by 1, 2
union all
select 'fact_csm_production', p.product_code, count(*)
from {{ ref('fact_csm_production') }} p
join (select distinct product_code from {{ ref('fact_csm_product_cost') }}) c
  on c.product_code = p.product_code
where p.factory_code is null
group by 1, 2
