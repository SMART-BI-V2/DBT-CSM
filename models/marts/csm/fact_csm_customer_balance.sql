{{ config(tags=['csm']) }}

select
  "CustomerNo"::text as customer_code,
  {{ csm_period_columns('"PostingDate"') }},
  sum(coalesce("Amount",0))::numeric(18,2) as amount,
  sum(coalesce("DebitAmount",0))::numeric(18,2) as debit_amount,
  sum(coalesce("CreditAmount",0))::numeric(18,2) as credit_amount,
  sum(coalesce("AmountLCY",0))::numeric(18,2) as amount_lcy,
  sum(coalesce("DebitAmountLCY",0))::numeric(18,2) as debit_amount_lcy,
  sum(coalesce("CreditAmountLCY",0))::numeric(18,2) as credit_amount_lcy
from {{ ref('stg_csm__customer_balance') }}
group by 1,2,3
