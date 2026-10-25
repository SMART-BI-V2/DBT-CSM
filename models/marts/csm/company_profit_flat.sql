{{ config(tags=['csm'], duplicate_key=['source_row_id'], distributed_by=['source_row_id']) }}

-- Báo cáo kết quả kinh doanh công ty theo dòng chỉ tiêu (Ord 1–18) × tháng.
select
  CAST(`RowID` AS BIGINT) as source_row_id,
  CAST(`Lecture` AS VARCHAR(512)) as section,
  CAST(`Description` AS VARCHAR(1024)) as description,
  CAST(`AccountName` AS VARCHAR(64)) as account_name,
  CAST(`Ord` AS INT) as ord,
  CAST(`Amount` AS DECIMAL(28,10)) as amount,
  {{ csm_period_columns('`PostingDate`') }},
  CAST(`PostingDate` AS DATE) as posting_date,
  CAST(`SystemDate` AS DATE) as system_date
from {{ ref('stg_csm__company_profit') }}
