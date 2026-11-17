-- factory_code quy về (kế hoạch / nhập–xuất–tồn thành phẩm) phải là xí nghiệp có thật trong
-- dim_csm_factory (NULL được phép — SP không có dấu vết giá thành; mã lạ ⇒ lỗi nguồn hoặc sai logic gán).
select 'fact_csm_production_plan' as tbl, p.factory_code, count(*) as n_rows
from {{ ref('fact_csm_production_plan') }} p
where p.factory_code is not null
  and p.factory_code not in (select factory_code from {{ ref('dim_csm_factory') }})
group by 1, 2
union all
select 'fact_csm_fg_inventory', p.factory_code, count(*)
from {{ ref('fact_csm_fg_inventory') }} p
where p.factory_code is not null
  and p.factory_code not in (select factory_code from {{ ref('dim_csm_factory') }})
group by 1, 2
union all
select 'fact_csm_production', p.factory_code, count(*)
from {{ ref('fact_csm_production') }} p
where p.factory_code is not null
  and p.factory_code not in (select factory_code from {{ ref('dim_csm_factory') }})
group by 1, 2
