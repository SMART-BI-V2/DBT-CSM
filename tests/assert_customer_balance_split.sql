-- Phải thu (dư Nợ) − trả trước (dư Có) = dư ròng; hai phần không âm và không cùng có số.
select customer_code, period_from, balance_end_lcy, receivable_lcy, prepayment_lcy
from {{ ref('fact_csm_customer_balance') }}
where abs(receivable_lcy - prepayment_lcy - balance_end_lcy) > 0.01
   or abs(receivable - prepayment - balance_end) > 0.01
   or receivable_lcy < 0 or prepayment_lcy < 0
   or (receivable_lcy > 0 and prepayment_lcy > 0)
