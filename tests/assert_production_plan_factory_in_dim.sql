-- factory_code quy về cho kế hoạch sản xuất phải là xí nghiệp có thật trong dim_csm_factory
-- (NULL được phép — SP không có dấu vết giá thành; mã lạ ⇒ lỗi nguồn hoặc sai logic gán).
select p.factory_code, count(*) as n_rows
from {{ ref('fact_csm_production_plan') }} p
where p.factory_code is not null
  and p.factory_code not in (
    select factory_code from {{ ref('dim_csm_factory') }}
  )
group by 1
