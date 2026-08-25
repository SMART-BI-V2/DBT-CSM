{{ config(tags=['csm']) }}

select
  "CustomerNo"::text as customer_code,
  "ItemNo"::text as product_code,
  "DocumentType"::text as doc_type,
  "DocumentNo"::text as doc_no,
  "ResponsibilityCenter"::text as responsibility_center,
  {{ csm_period_columns('"PostingDate"') }},
  coalesce("Quantity",0)::numeric as qty,
  coalesce("Amount",0)::numeric as amount,
  coalesce("VATBaseAmount",0)::numeric as vat_base,
  coalesce("VATAmount",0)::numeric as vat_amount,
  ("Amount" / nullif("Quantity",0))::numeric as unit_price,
  coalesce("LineDiscountAmount",0)::numeric as line_discount
from {{ ref('stg_csm__sale_invoice') }}
