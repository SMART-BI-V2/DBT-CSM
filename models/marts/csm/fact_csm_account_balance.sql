{{ config(tags=['csm'], duplicate_key=['account_no'], distributed_by=['account_no']) }}

-- Số dư tài khoản. Nguồn balance_account hiện rỗng (dev lẫn prod).
select
  CAST(`AccountNo` AS VARCHAR(64)) as account_no,
  CAST(max(`AccountName`) AS VARCHAR(512)) as account_name,
  CAST(max(`AccountType`) AS INT) as account_type,
  CAST(coalesce(`SourceCode`, '') AS VARCHAR(16)) as factory_code,
  {{ csm_period_columns('`PostingDate`') }},
  CAST(sum(coalesce(`BegDebitAmount`, 0)) AS DECIMAL(18,2)) as beg_debit_amount,
  CAST(sum(coalesce(`BegCreditAmount`, 0)) AS DECIMAL(18,2)) as beg_credit_amount,
  CAST(sum(coalesce(`DebitAmount`, 0)) AS DECIMAL(18,2)) as debit_amount,
  CAST(sum(coalesce(`CreditAmount`, 0)) AS DECIMAL(18,2)) as credit_amount,
  CAST(sum(coalesce(`EndDebitAmount`, 0)) AS DECIMAL(18,2)) as end_debit_amount,
  CAST(sum(coalesce(`EndCreditAmount`, 0)) AS DECIMAL(18,2)) as end_credit_amount
from {{ ref('stg_csm__balance_account') }}
group by 1, 4, 5, 6
