{{ config(tags=['csm'], duplicate_key=['factory_code', 'doc_type', 'doc_no'], distributed_by=['doc_no']) }}

-- Doanh thu dịch vụ (gộp theo chứng từ). Tổng doanh thu công ty = fact_csm_sales.amount + bảng này.
select
  CAST(coalesce(`SourceCode`, '') AS VARCHAR(16)) as factory_code,
  CAST(`DocumentType` AS VARCHAR(16)) as doc_type,
  CAST(`DocumentNo` AS VARCHAR(128)) as doc_no,
  CAST(max(`ExternalDocumentNo`) AS VARCHAR(256)) as external_doc_no,
  {{ csm_period_columns('`PostingDate`') }},
  -- Ngày ghi sổ — để dự báo theo TUẦN (Forecast) và phân tích theo ngày.
  -- Một chứng từ một ngày ghi sổ; max() để không đổi khoá gộp (group by theo vị trí bên dưới).
  CAST(max(`PostingDate`) AS DATE) as posting_date,
  CAST(sum(coalesce(`Amount`, 0)) AS DECIMAL(18,3)) as amount
from {{ ref('stg_csm__service_invoice') }}
group by 1, 2, 3, 5, 6
