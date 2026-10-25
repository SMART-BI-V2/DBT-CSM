-- Lãi gộp phải tính từ doanh thu − giá vốn (không phải BusinessProfit của ERP — lỗi trước 10/2026),
-- lãi gộp sau chiết khấu = lãi gộp − 3 khoản chiết khấu.
select factory_code, product_code, doc_type, period_from, sale_actual, cost_actual, gross_profit, gross_profit_after_discount
from {{ ref('fact_csm_product_profit') }}
where abs(gross_profit - (sale_actual - cost_actual)) > 0.01
   or abs(gross_profit_after_discount - (gross_profit - discount_amt - discount_business - discount_paid)) > 0.01
