{{ config(tags=['csm'], duplicate_key=['period_date', 'product_code'], distributed_by=['product_code']) }}

-- Nhập / xuất / tồn THÀNH PHẨM theo SP × tháng (toàn công ty); period_date = NGÀY ĐẦU tháng.
--
-- Nguồn production_entry: dòng tháng (ngày 1) chỉ có phát sinh; dòng CHỤP SỐ DƯ (ngày cuối tháng,
-- vd 31/12/2024) chỉ có QuantityBegin/ValueBegin = tồn cuối tháng đó. QuantityEnding/ValueEnding
-- của ERP luôn = 0 ⇒ bản PG cũ ra tồn = 0.
-- qty_input / qty_output = nhập SX / xuất bán (nội địa + xuất khẩu) như bản cũ; tồn phải dùng
-- *_total (gồm mọi loại nhập/xuất khác).
-- [SỬA] qty_ending = số chụp tại mốc gần nhất + Σ(InputTotal − OutputTotal) các tháng sau mốc;
--   qty_begin = tồn cuối tháng trước. Đã đối chiếu: SL tồn cuối 12/2024 tính từ dev = số chụp ERP
--   trên prod cho 1.723/1.723 mã. GIÁ TRỊ tồn tính theo luồng chỉ là xấp xỉ (ERP đánh giá lại giá
--   vốn cuối kỳ; lệch ~16% sau 3 năm) — dùng SL tồn làm chuẩn.
-- [SỬA] dòng điều chỉnh tiền (|SL| = |giá trị|, vd mã 2930 tháng 12/2025) không tính vào số lượng.
with src as (
  select
    `ItemNo` as product_code,
    {{ csm_month('`PostingDate`') }} as mth,
    DAY(`PostingDate`) <> 1 as is_snap,
    {{ csm_is_money_in_qty('`QuantityOutput`', '`ValueOutput`') }} as is_money,
    t.*
  from {{ ref('stg_csm__production_entry') }} t
),
mv as (
  select product_code, mth,
    sum(case when is_money then 0 else coalesce(`QuantityInput`,0) end) q_in,   sum(coalesce(`ValueInput`,0)) v_in,
    sum(case when is_money then 0 else coalesce(`QuantityOutput`,0) end) q_out, sum(coalesce(`ValueOutput`,0)) v_out,
    sum(case when is_money then 0 else coalesce(`QuantityInland`,0) end) q_inl, sum(coalesce(`ValueInland`,0)) v_inl,
    sum(case when is_money then 0 else coalesce(`QuantityExport`,0) end) q_exp, sum(coalesce(`ValueExport`,0)) v_exp,
    sum(case when is_money then 0 else coalesce(`QuantityInputTotal`,0) end) q_int,   sum(coalesce(`ValueInputTotal`,0)) v_int,
    sum(case when is_money then 0 else coalesce(`QuantityOutputTotal`,0) end) q_outt, sum(coalesce(`ValueOutputTotal`,0)) v_outt
  from src where not is_snap
  group by 1, 2
),
snap as (
  select product_code, mth, sum(coalesce(`QuantityBegin`,0)) q_snap, sum(coalesce(`ValueBegin`,0)) v_snap
  from src where is_snap
  group by 1, 2
),
months as (select distinct mth from src),
snap_months as (select distinct mth from src where is_snap),
anchors as (
  select m.mth, max(s.mth) as anchor
  from months m left join snap_months s on s.mth <= m.mth
  group by m.mth
),
key_months as (select product_code, min(mth) as first_mth from src group by 1),
grid as (
  select k.product_code, m.mth, a.anchor,
    coalesce(v.q_in,0) q_in, coalesce(v.v_in,0) v_in, coalesce(v.q_out,0) q_out, coalesce(v.v_out,0) v_out,
    coalesce(v.q_inl,0) q_inl, coalesce(v.v_inl,0) v_inl, coalesce(v.q_exp,0) q_exp, coalesce(v.v_exp,0) v_exp,
    coalesce(v.q_int,0) q_int, coalesce(v.v_int,0) v_int, coalesce(v.q_outt,0) q_outt, coalesce(v.v_outt,0) v_outt,
    coalesce(s.q_snap,0) q_snap, coalesce(s.v_snap,0) v_snap,
    (v.mth is not null or s.mth is not null) as has_src
  from key_months k
  join months m on m.mth >= k.first_mth
  join anchors a on a.mth = m.mth
  left join mv v on v.product_code = k.product_code and v.mth = m.mth
  left join snap s on s.product_code = k.product_code and s.mth = m.mth
),
bal as (
  select g.*,
    sum(case when g.mth = g.anchor then g.q_snap
             when g.anchor is null or g.mth > g.anchor then g.q_int - g.q_outt else 0 end)
      over (partition by g.product_code, g.anchor order by g.mth rows between unbounded preceding and current row) as q_end,
    sum(case when g.mth = g.anchor then g.v_snap
             when g.anchor is null or g.mth > g.anchor then g.v_int - g.v_outt else 0 end)
      over (partition by g.product_code, g.anchor order by g.mth rows between unbounded preceding and current row) as v_end
  from grid g
),
fin as (
  select b.*,
    lag(q_end, 1, 0) over (partition by product_code order by mth) as q_beg,
    lag(v_end, 1, 0) over (partition by product_code order by mth) as v_beg
  from bal b
)
select
  mth as period_date,
  CAST(product_code AS VARCHAR(128)) as product_code,
  CAST(q_beg AS DECIMAL(18,4)) as qty_begin,   CAST(v_beg AS DECIMAL(18,2)) as val_begin,
  CAST(q_in AS DECIMAL(18,4)) as qty_input,    CAST(v_in AS DECIMAL(18,2)) as val_input,
  CAST(q_out AS DECIMAL(18,4)) as qty_output,  CAST(v_out AS DECIMAL(18,2)) as val_output,
  CAST(q_end AS DECIMAL(18,4)) as qty_ending,  CAST(v_end AS DECIMAL(18,2)) as val_ending,
  CAST(q_inl AS DECIMAL(18,4)) as qty_inland,  CAST(v_inl AS DECIMAL(18,2)) as val_inland,
  CAST(q_exp AS DECIMAL(18,4)) as qty_export,  CAST(v_exp AS DECIMAL(18,2)) as val_export,
  CAST(q_int AS DECIMAL(18,4)) as qty_input_total,   CAST(v_int AS DECIMAL(18,2)) as val_input_total,
  CAST(q_outt AS DECIMAL(18,4)) as qty_output_total, CAST(v_outt AS DECIMAL(18,2)) as val_output_total
from fin
where has_src or q_end <> 0 or v_end <> 0 or q_beg <> 0 or v_beg <> 0
