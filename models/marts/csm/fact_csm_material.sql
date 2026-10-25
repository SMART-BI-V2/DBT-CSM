{{ config(tags=['csm'], duplicate_key=['period_date', 'factory_code', 'material_code'], distributed_by=['material_code'], buckets=3) }}

-- Nhập / xuất / tồn NVL theo XN × vật tư × tháng; period_date = NGÀY ĐẦU tháng.
--
-- Nguồn material_entry: dòng tháng (ngày 1) chỉ có phát sinh; dòng CHỤP SỐ DƯ (ngày cuối tháng,
-- vd 31/12/2024 trên prod, 31/12/2021 trên dev) chỉ có QtyDau/AmountDau = tồn cuối tháng đó.
-- Cột QtyTon/AmountTon của ERP luôn = 0 ⇒ bản PG cũ ra tồn = 0.
-- [SỬA] tồn cuối tháng = số chụp tại mốc gần nhất + Σ(Nhập tổng − Xuất tổng) các tháng sau mốc.
--   Đã đối chiếu: tồn cuối 12/2024 tính từ dev = số chụp đầu kỳ ERP trên prod (646,1 / 643,5 tỷ,
--   khớp từng XN trừ XN 02). Lưới đầy đủ XN × vật tư × tháng ⇒ lọc 1 tháng ra đủ tồn kho.
--   Dòng chụp số dư hiện ở tháng của nó (vd 2024-12-01) với phát sinh = 0, qty_ton = số chụp.
-- Thêm cột: qty_dau/val_dau (tồn đầu tháng), *_nhap_total / *_xuat_total (mọi loại nhập/xuất).
with src as (
  select
    `SourceCode` as factory_code,
    `ItemNo` as material_code,
    {{ csm_month('`PostingDate`') }} as mth,
    DAY(`PostingDate`) <> 1 as is_snap,
    `QtyDau`, `AmountDau`, `QtyNhapTotal`, `AmountNhapTotal`, `QtyXuatTotal`, `AmountXuatTotal`,
    `QtyNhapKho`, `AmountNhapKho`, `QtyXuatKho`, `AmountXuatKho`, `QtyXuatSX`, `AmountXuatSX`, `QtyNhapSX`, `AmountNhapSX`
  from {{ ref('stg_csm__material_entry') }}
),
mv as (   -- phát sinh tháng
  select factory_code, material_code, mth,
    sum(coalesce(`QtyNhapKho`,0)) q_nk, sum(coalesce(`AmountNhapKho`,0)) v_nk,
    sum(coalesce(`QtyXuatKho`,0)) q_xk, sum(coalesce(`AmountXuatKho`,0)) v_xk,
    sum(coalesce(`QtyXuatSX`,0)) q_xsx, sum(coalesce(`AmountXuatSX`,0)) v_xsx,
    sum(coalesce(`QtyNhapSX`,0)) q_nsx, sum(coalesce(`AmountNhapSX`,0)) v_nsx,
    sum(coalesce(`QtyNhapTotal`,0)) q_nt, sum(coalesce(`AmountNhapTotal`,0)) v_nt,
    sum(coalesce(`QtyXuatTotal`,0)) q_xt, sum(coalesce(`AmountXuatTotal`,0)) v_xt
  from src where not is_snap
  group by 1, 2, 3
),
snap as (  -- số dư chụp cuối tháng
  select factory_code, material_code, mth, sum(coalesce(`QtyDau`,0)) q_snap, sum(coalesce(`AmountDau`,0)) v_snap
  from src where is_snap
  group by 1, 2, 3
),
months as (select distinct mth from src),
snap_months as (select distinct mth from src where is_snap),
anchors as (
  select m.mth, max(s.mth) as anchor
  from months m left join snap_months s on s.mth <= m.mth
  group by m.mth
),
key_months as (select factory_code, material_code, min(mth) as first_mth from src group by 1, 2),
grid as (
  select k.factory_code, k.material_code, m.mth, a.anchor,
    coalesce(v.q_nk,0) q_nk, coalesce(v.v_nk,0) v_nk, coalesce(v.q_xk,0) q_xk, coalesce(v.v_xk,0) v_xk,
    coalesce(v.q_xsx,0) q_xsx, coalesce(v.v_xsx,0) v_xsx, coalesce(v.q_nsx,0) q_nsx, coalesce(v.v_nsx,0) v_nsx,
    coalesce(v.q_nt,0) q_nt, coalesce(v.v_nt,0) v_nt, coalesce(v.q_xt,0) q_xt, coalesce(v.v_xt,0) v_xt,
    coalesce(s.q_snap,0) q_snap, coalesce(s.v_snap,0) v_snap,
    (v.mth is not null or s.mth is not null) as has_src
  from key_months k
  join months m on m.mth >= k.first_mth
  join anchors a on a.mth = m.mth
  left join mv v on v.factory_code = k.factory_code and v.material_code = k.material_code and v.mth = m.mth
  left join snap s on s.factory_code = k.factory_code and s.material_code = k.material_code and s.mth = m.mth
),
bal as (
  select g.*,
    sum(case when g.mth = g.anchor then g.q_snap
             when g.anchor is null or g.mth > g.anchor then g.q_nt - g.q_xt else 0 end)
      over (partition by g.factory_code, g.material_code, g.anchor order by g.mth rows between unbounded preceding and current row) as q_ton,
    sum(case when g.mth = g.anchor then g.v_snap
             when g.anchor is null or g.mth > g.anchor then g.v_nt - g.v_xt else 0 end)
      over (partition by g.factory_code, g.material_code, g.anchor order by g.mth rows between unbounded preceding and current row) as v_ton
  from grid g
),
fin as (
  select b.*,
    lag(q_ton, 1, 0) over (partition by factory_code, material_code order by mth) as q_dau,
    lag(v_ton, 1, 0) over (partition by factory_code, material_code order by mth) as v_dau
  from bal b
)
select
  mth as period_date,
  CAST(factory_code AS VARCHAR(16)) as factory_code,
  CAST(material_code AS VARCHAR(128)) as material_code,
  CAST(q_nk AS DECIMAL(18,4)) as qty_nhap_kho,   CAST(v_nk AS DECIMAL(18,2)) as val_nhap_kho,
  CAST(q_xk AS DECIMAL(18,4)) as qty_xuat_kho,   CAST(v_xk AS DECIMAL(18,2)) as val_xuat_kho,
  CAST(q_xsx AS DECIMAL(18,4)) as qty_xuat_sx,   CAST(v_xsx AS DECIMAL(18,2)) as val_xuat_sx,
  CAST(q_nsx AS DECIMAL(18,4)) as qty_nhap_sx,   CAST(v_nsx AS DECIMAL(18,2)) as val_nhap_sx,
  CAST(q_ton AS DECIMAL(18,4)) as qty_ton,       CAST(v_ton AS DECIMAL(18,2)) as val_ton,
  CAST(q_dau AS DECIMAL(18,4)) as qty_dau,       CAST(v_dau AS DECIMAL(18,2)) as val_dau,
  CAST(q_nt AS DECIMAL(18,4)) as qty_nhap_total, CAST(v_nt AS DECIMAL(18,2)) as val_nhap_total,
  CAST(q_xt AS DECIMAL(18,4)) as qty_xuat_total, CAST(v_xt AS DECIMAL(18,2)) as val_xuat_total
from fin
-- bỏ ô trống hoàn toàn (không phát sinh, tồn đầu và cuối đều 0)
where has_src or q_ton <> 0 or v_ton <> 0 or q_dau <> 0 or v_dau <> 0
