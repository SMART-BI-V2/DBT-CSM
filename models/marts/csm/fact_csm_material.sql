{{ config(tags=['csm']) }}

select
  "PostingDate"::date as period_date,
  "SourceCode"::text as factory_code,
  "ItemNo"::text as material_code,
  sum(coalesce("QtyNhapKho",0))::numeric(18,4) as qty_nhap_kho,
  sum(coalesce("AmountNhapKho",0))::numeric(18,2) as val_nhap_kho,
  sum(coalesce("QtyXuatKho",0))::numeric(18,4) as qty_xuat_kho,
  sum(coalesce("AmountXuatKho",0))::numeric(18,2) as val_xuat_kho,
  sum(coalesce("QtyXuatSX",0))::numeric(18,4) as qty_xuat_sx,
  sum(coalesce("AmountXuatSX",0))::numeric(18,2) as val_xuat_sx,
  sum(coalesce("QtyNhapSX",0))::numeric(18,4) as qty_nhap_sx,
  sum(coalesce("AmountNhapSX",0))::numeric(18,2) as val_nhap_sx,
  sum(coalesce("QtyTon",0))::numeric(18,4) as qty_ton,
  sum(coalesce("AmountTon",0))::numeric(18,2) as val_ton
from {{ ref('stg_csm__material_entry') }}
group by 1,2,3
