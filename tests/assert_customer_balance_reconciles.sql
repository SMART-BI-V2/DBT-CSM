-- Dư nợ cuối kỳ cuối cùng của từng KH = tổng phát sinh (gồm số dư đầu kỳ) ở nguồn.
with last_bal as (
  select customer_code, balance_end_lcy,
         row_number() over (partition by customer_code order by period_from desc) as rn
  from {{ ref('fact_csm_customer_balance') }}
),
src as (
  select {{ csm_code('`CustomerNo`') }} as customer_code, sum(`AmountLCY`) as amt
  from {{ source('csm', 'customer_balance') }} group by 1
)
select s.customer_code, s.amt, l.balance_end_lcy
from src s left join last_bal l on l.customer_code = s.customer_code and l.rn = 1
where abs(coalesce(l.balance_end_lcy, 0) - s.amt) > 1
