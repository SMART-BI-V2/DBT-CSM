-- Đẳng thức tồn: cuối = đầu + nhập tổng − xuất tổng, trừ ô (mã × tháng) có dòng chụp số dư của CHÍNH mã đó
-- (tồn = số chụp). Mốc chụp tính riêng từng mã ⇒ dòng chụp thêm cho vài mã không được làm lệch mã khác.
with mat_snap as (
  select distinct {{ csm_trim('`SourceCode`') }} as k1, {{ csm_code('`ItemNo`') }} as k2,
         CAST(DATE_TRUNC(`PostingDate`, 'month') AS DATE) as m
  from {{ source('csm', 'material_entry') }} where DAY(`PostingDate`) <> 1
),
fg_snap as (
  select distinct {{ csm_code('`ItemNo`') }} as k2, CAST(DATE_TRUNC(`PostingDate`, 'month') AS DATE) as m
  from {{ source('csm', 'production_entry') }} where DAY(`PostingDate`) <> 1
)
select 'material' as tbl, f.period_date, f.factory_code as k1, f.material_code as k2
from {{ ref('fact_csm_material') }} f
left join mat_snap s on s.k1 = f.factory_code and s.k2 = f.material_code and s.m = f.period_date
where s.m is null
  and (abs(f.qty_ton - (f.qty_dau + f.qty_nhap_total - f.qty_xuat_total)) > 0.01
       or abs(f.val_ton - (f.val_dau + f.val_nhap_total - f.val_xuat_total)) > 1)
union all
select 'fg', f.period_date, '', f.product_code
from {{ ref('fact_csm_fg_inventory') }} f
left join fg_snap s on s.k2 = f.product_code and s.m = f.period_date
where s.m is null
  and (abs(f.qty_ending - (f.qty_begin + f.qty_input_total - f.qty_output_total)) > 0.01
       or abs(f.val_ending - (f.val_begin + f.val_input_total - f.val_output_total)) > 1)
