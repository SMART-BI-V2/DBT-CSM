{{ config(tags=['csm'], duplicate_key=['period_date', 'product_code'], distributed_by=['product_code']) }}

-- Kế hoạch sản xuất theo SP × tháng; period_date = NGÀY ĐẦU tháng.
-- [SỬA] dòng kế hoạch giảm trừ (mã giả 2900xx…) ERP ghi SỐ TIỀN vào QuantityOutput/QuantityInland
-- (dev 2024: 99,96% "sản lượng kế hoạch" là số tiền) ⇒ không tính vào số lượng; giá trị giữ nguyên.
-- [SỬA 11/2026] thêm factory_code: nguồn ERP không ghi xí nghiệp cho kế hoạch (production_planning
-- không có SourceCode, số liệu là toàn công ty) ⇒ quy về MỘT xí nghiệp theo dấu vết GIÁ THÀNH của cùng
-- sản phẩm (fact_csm_product_cost): cùng tháng → XN có sản lượng lớn nhất; tháng chưa có giá thành
-- (số tạm) hoặc SP không sản xuất tháng đó → XN gần nhất của SP. Không xác định được → NULL.
-- Đã kiểm trên raw_stage (11/2026): phủ 99,985% giá trị kế hoạch; chỉ 24/4.691 SP từng qua >1 XN.
with plan as (
  select
    {{ csm_month('`PostingDate`') }} as period_date,
    CAST(`ItemNo` AS VARCHAR(128)) as product_code,
    CAST(sum(case when is_money then 0 else coalesce(`QuantityInput`,0) end) AS DECIMAL(18,4)) as qty_plan,
    CAST(sum(coalesce(`ValueInput`,0)) AS DECIMAL(18,2)) as val_plan,
    CAST(sum(case when is_money then 0 else coalesce(`QuantityOutput`,0) end) AS DECIMAL(18,4)) as qty_output,
    CAST(sum(coalesce(`ValueOutput`,0)) AS DECIMAL(18,2)) as val_output,
    CAST(sum(case when is_money then 0 else coalesce(`QuantityInland`,0) end) AS DECIMAL(18,4)) as qty_inland,
    CAST(sum(case when is_money then 0 else coalesce(`QuantityExport`,0) end) AS DECIMAL(18,4)) as qty_export
  from (
    select p.*, {{ csm_is_money_in_qty('p.`QuantityOutput`', 'p.`ValueOutput`') }} as is_money
    from {{ ref('stg_csm__production_planning') }} p
  ) x
  group by 1, 2
),
cost_factory as (
  select product_code, period_from, factory_code, qty
  from {{ ref('fact_csm_product_cost') }}
),
-- XN của SP theo TỪNG tháng giá thành: 1 kỳ có nhiều XN (hiếm) → XN có sản lượng lớn nhất
map_period as (
  select product_code, period_from, factory_code
  from (
    select product_code, period_from, factory_code,
           row_number() over (partition by product_code, period_from
                              order by qty desc, factory_code) as rn
    from cost_factory
  ) t
  where rn = 1
),
-- XN GẦN NHẤT của SP: dùng cho tháng chưa khoá sổ / tháng SP không có giá thành
map_latest as (
  select product_code, factory_code
  from (
    select product_code, factory_code,
           row_number() over (partition by product_code
                              order by period_from desc, qty desc, factory_code) as rn
    from cost_factory
  ) t
  where rn = 1
)
select
  plan.period_date,
  plan.product_code,
  coalesce(mp.factory_code, ml.factory_code) as factory_code,
  plan.qty_plan,
  plan.val_plan,
  plan.qty_output,
  plan.val_output,
  plan.qty_inland,
  plan.qty_export
from plan
left join map_period mp on mp.product_code = plan.product_code
                       and mp.period_from = plan.period_date
left join map_latest ml on ml.product_code = plan.product_code
