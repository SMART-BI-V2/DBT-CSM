-- Đẳng thức tồn: cuối = đầu + nhập tổng − xuất tổng (trừ tháng chụp số dư, nơi tồn = số chụp).
with snap_months as (
  select distinct CAST(DATE_TRUNC(`PostingDate`, 'month') AS DATE) as m
  from {{ source('csm', 'material_entry') }} where DAY(`PostingDate`) <> 1
),
fg_snap as (
  select distinct CAST(DATE_TRUNC(`PostingDate`, 'month') AS DATE) as m
  from {{ source('csm', 'production_entry') }} where DAY(`PostingDate`) <> 1
)
select 'material' as tbl, period_date, factory_code as k1, material_code as k2
from {{ ref('fact_csm_material') }}
where period_date not in (select m from snap_months)
  and abs(qty_ton - (qty_dau + qty_nhap_total - qty_xuat_total)) > 0.01
union all
select 'fg', period_date, '', product_code
from {{ ref('fact_csm_fg_inventory') }}
where period_date not in (select m from fg_snap)
  and abs(qty_ending - (qty_begin + qty_input_total - qty_output_total)) > 0.01
