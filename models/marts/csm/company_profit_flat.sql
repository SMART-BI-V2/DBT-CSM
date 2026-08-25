{{ config(tags=['csm']) }}

select
  "RowID"::integer as source_row_id,
  "Lecture"::text as section,
  "Description"::text as description,
  "AccountName"::text as account_name,
  "Ord"::integer as ord,
  "Amount"::numeric(28,10) as amount,
  {{ csm_period_columns('"PostingDate"') }},
  "PostingDate"::date as posting_date,
  "SystemDate"::date as system_date
from {{ ref('stg_csm__company_profit') }}
