{{ config(tags=['csm']) }}

select
  "AccountNo"::text as account_no,
  max("AccountName")::text as account_name,
  max("AccountType")::integer as account_type,
  coalesce("SourceCode",'')::text as factory_code,
  {{ csm_period_columns('"PostingDate"') }},
  sum(coalesce("BegDebitAmount",0))::numeric(18,2) as beg_debit_amount,
  sum(coalesce("BegCreditAmount",0))::numeric(18,2) as beg_credit_amount,
  sum(coalesce("DebitAmount",0))::numeric(18,2) as debit_amount,
  sum(coalesce("CreditAmount",0))::numeric(18,2) as credit_amount,
  sum(coalesce("EndDebitAmount",0))::numeric(18,2) as end_debit_amount,
  sum(coalesce("EndCreditAmount",0))::numeric(18,2) as end_credit_amount
from {{ ref('stg_csm__balance_account') }}
group by 1,4,5,6
