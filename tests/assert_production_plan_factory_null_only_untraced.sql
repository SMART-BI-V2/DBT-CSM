-- factory_code của kế hoạch sản xuất chỉ được NULL khi SP CHƯA TỪNG có giá thành
-- (không có dấu vết xí nghiệp nào). SP đã có giá thành mà vẫn NULL ⇒ hỏng logic gán
-- (vd lệch kiểu/chuẩn hoá mã khi join map_period/map_latest).
select p.product_code, count(*) as n_rows
from {{ ref('fact_csm_production_plan') }} p
join (select distinct product_code from {{ ref('fact_csm_product_cost') }}) c
  on c.product_code = p.product_code
where p.factory_code is null
group by 1
