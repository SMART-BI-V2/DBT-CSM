{{ config(tags=['csm']) }}

select
  coalesce("SourceCode",'')::text as factory_code,
  "DocumentType"::text as doc_type,
  "DocumentNo"::text as doc_no,
  max("ExternalDocumentNo")::text as external_doc_no,
  {{ csm_period_columns('"PostingDate"') }},
  sum(coalesce("Amount",0))::numeric(18,3) as amount
from {{ ref('stg_csm__service_invoice') }}
group by 1,2,3,5,6
