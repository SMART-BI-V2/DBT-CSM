{{ config(severity='warn') }}
-- Lãi kinh doanh ERP ≈ lãi gộp − các khoản chi phí ERP xuất ra. Phần dư (khoản ERP không xuất cột riêng,
-- tỷ lệ cố định trên doanh thu theo nhóm hàng nội địa) 2025–2026 chỉ 0,2–1,2% doanh thu tháng.
-- Vượt 3% ⇒ ERP thêm / đổi nghĩa khoản chi phí: rà lại ánh xạ cột trong fact_csm_product_profit.
select period_from, sum(sale_actual) as sale_actual,
  sum(gross_profit - (warranty + discount_amt + discount_business + discount_paid + bonus_cost + sale_cost
                      + manage_cost + debt_cost + sale_return_cost) - business_profit) as residual
from {{ ref('fact_csm_product_profit') }}
group by period_from
having abs(sum(gross_profit - (warranty + discount_amt + discount_business + discount_paid + bonus_cost + sale_cost
                               + manage_cost + debt_cost + sale_return_cost) - business_profit))
       > 0.03 * greatest(abs(sum(sale_actual)), 1)
