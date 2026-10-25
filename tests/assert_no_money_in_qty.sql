-- Số lượng không được chứa số tiền (dòng điều chỉnh của ERP).
select 'sales' as tbl, product_code, period_from, qty, amount
from {{ ref('fact_csm_sales') }}
where qty <> 0 and abs(abs(qty) - abs(amount)) < 1
