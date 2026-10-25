{{ config(tags=['csm'], duplicate_key=['factory_code', 'doc_type', 'doc_no'], distributed_by=['doc_no']) }}

-- Doanh thu dịch vụ (gộp theo chứng từ). Tổng doanh thu công ty = fact_csm_sales.amount + bảng này.
select
  CAST(coalesce(`SourceCode`, '') AS VARCHAR(16)) as factory_code,
  CAST(`DocumentType` AS VARCHAR(16)) as doc_type,
  CAST(`DocumentNo` AS VARCHAR(128)) as doc_no,
  CAST(max(`ExternalDocumentNo`) AS VARCHAR(256)) as external_doc_no,
  {{ csm_period_columns('`PostingDate`') }},
  CAST(sum(coalesce(`Amount`, 0)) AS DECIMAL(18,3)) as amount
from {{ ref('stg_csm__service_invoice') }}
group by 1, 2, 3, 5, 6
