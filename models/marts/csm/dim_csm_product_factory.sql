{{ config(tags=['csm'], duplicate_key=['product_code', 'period_from'], distributed_by=['product_code']) }}

-- Map sản phẩm → xí nghiệp, dùng chung cho các bảng ERP không ghi mã xí nghiệp (kế hoạch
-- production_planning, nhập-xuất-tồn thành phẩm production_entry đều không có SourceCode).
-- Nguồn dấu vết = GIÁ THÀNH (fact_csm_product_cost): mỗi SP × kỳ lấy XN có sản lượng lớn nhất
-- (trường hợp hiếm một kỳ có nhiều XN). Đã kiểm trên raw_stage (11/2026): phủ 99,985% giá trị
-- kế hoạch; chỉ 24/4.691 SP từng qua >1 XN.
-- Grain (product_code, period_from); is_latest = 1 cho kỳ gần nhất của SP ⇒ trả lời
-- "sản phẩm này thuộc xí nghiệp nào". Bảng fact dùng 2 lần join: cùng kỳ (period_from = period_date)
-- rồi fallback is_latest = 1 — xem fact_csm_production_plan / fact_csm_fg_inventory.
with per_period as (
  select product_code, period_from, factory_code, qty
  from (
    select product_code, period_from, factory_code, sum(qty) as qty,
           row_number() over (partition by product_code, period_from
                              order by sum(qty) desc, factory_code) as rn
    from {{ ref('fact_csm_product_cost') }}
    group by 1, 2, 3
  ) t
  where rn = 1
)
select
  product_code,
  period_from,
  factory_code,
  CAST(qty AS DECIMAL(38,10)) as qty,
  CAST(case when row_number() over (partition by product_code order by period_from desc) = 1
            then 1 else 0 end AS TINYINT) as is_latest
from per_period
