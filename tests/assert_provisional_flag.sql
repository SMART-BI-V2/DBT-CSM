-- is_provisional: tháng hiện tại luôn là số tạm; tháng đã có giá thành (đã khoá sổ) không được là số tạm.
with closed as (select distinct period_from as m from {{ ref('fact_csm_product_cost') }}),
cur as (select CAST(DATE_TRUNC(CURDATE(), 'month') AS DATE) as m)
select 'material' as tbl, f.period_date, f.is_provisional
from {{ ref('fact_csm_material') }} f cross join cur
left join closed c on c.m = f.period_date
where (f.period_date >= cur.m and f.is_provisional <> 1) or (c.m is not null and f.is_provisional <> 0)
union all
select 'fg', f.period_date, f.is_provisional
from {{ ref('fact_csm_fg_inventory') }} f cross join cur
left join closed c on c.m = f.period_date
where (f.period_date >= cur.m and f.is_provisional <> 1) or (c.m is not null and f.is_provisional <> 0)
