-- Tồn kho liền mạch giữa các tháng:
--  (a) mã còn tồn cuối tháng m (m chưa phải tháng cuối) phải có dòng tháng m+1 với tồn đầu = tồn cuối tháng m;
--  (b) không mã nào tụt về tồn 0 khi tháng trước còn tồn mà trong tháng không có phát sinh và không có dòng
--      chụp số dư của chính mã đó (lỗi mốc chụp dùng chung cả bảng trước 10/2026).
with mat as (select * from {{ ref('fact_csm_material') }}),
mat_last as (select max(period_date) as m from mat),
fg as (select * from {{ ref('fact_csm_fg_inventory') }}),
fg_last as (select max(period_date) as m from fg),
mat_snap as (
  select distinct {{ csm_trim('`SourceCode`') }} as k1, {{ csm_code('`ItemNo`') }} as k2,
         CAST(DATE_TRUNC(`PostingDate`, 'month') AS DATE) as m
  from {{ source('csm', 'material_entry') }} where DAY(`PostingDate`) <> 1
),
fg_snap as (
  select distinct {{ csm_code('`ItemNo`') }} as k2, CAST(DATE_TRUNC(`PostingDate`, 'month') AS DATE) as m
  from {{ source('csm', 'production_entry') }} where DAY(`PostingDate`) <> 1
)
select 'material: thiếu tháng sau / tồn đầu lệch' as chk, a.period_date, a.factory_code as k1, a.material_code as k2
from mat a
cross join mat_last l
left join mat b on b.factory_code = a.factory_code and b.material_code = a.material_code
               and b.period_date = date_add(a.period_date, interval 1 month)
where a.period_date < l.m and (a.qty_ton <> 0 or a.val_ton <> 0)
  and (b.period_date is null or abs(b.qty_dau - a.qty_ton) > 0.01 or abs(b.val_dau - a.val_ton) > 1)
union all
select 'material: tụt về 0 không phát sinh', f.period_date, f.factory_code, f.material_code
from mat f
left join mat_snap s on s.k1 = f.factory_code and s.k2 = f.material_code and s.m = f.period_date
where s.m is null and f.qty_dau <> 0 and f.qty_ton = 0 and f.qty_nhap_total = 0 and f.qty_xuat_total = 0
union all
select 'fg: thiếu tháng sau / tồn đầu lệch', a.period_date, '', a.product_code
from fg a
cross join fg_last l
left join fg b on b.product_code = a.product_code and b.period_date = date_add(a.period_date, interval 1 month)
where a.period_date < l.m and (a.qty_ending <> 0 or a.val_ending <> 0)
  and (b.period_date is null or abs(b.qty_begin - a.qty_ending) > 0.01 or abs(b.val_begin - a.val_ending) > 1)
union all
select 'fg: tụt về 0 không phát sinh', f.period_date, '', f.product_code
from fg f
left join fg_snap s on s.k2 = f.product_code and s.m = f.period_date
where s.m is null and f.qty_begin <> 0 and f.qty_ending = 0 and f.qty_input_total = 0 and f.qty_output_total = 0
